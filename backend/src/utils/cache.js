/**
 * Service de cache Redis amélioré
 * AgroSmart - Système Agricole Intelligent
 * 
 * Features:
 * - Cache météo (30 minutes)
 * - Cache parcelles utilisateur (5 minutes)
 * - Cache données capteurs (1 minute)
 * - Cache marketplace (10 minutes)
 * - Invalidation intelligente par pattern
 * - Compression pour les gros objets
 */

const Redis = require('ioredis');
const config = require('../config');
const logger = require('./logger');
const zlib = require('zlib');
const { promisify } = require('util');

const gzip = promisify(zlib.gzip);
const gunzip = promisify(zlib.gunzip);

let redisClient;

// Seuil de compression (1KB)
const COMPRESSION_THRESHOLD = 1024;

// TTL par défaut en secondes
const TTL = {
  WEATHER: 30 * 60,        // 30 minutes
  WEATHER_FORECAST: 60 * 60, // 1 heure
  PARCELLES: 5 * 60,       // 5 minutes
  SENSORS: 60,             // 1 minute
  MARKETPLACE: 10 * 60,    // 10 minutes
  USER_PROFILE: 15 * 60,   // 15 minutes
  FORMATIONS: 60 * 60,     // 1 heure
  REGIONS: 24 * 60 * 60,   // 24 heures
  DEFAULT: 60 * 60         // 1 heure
};

// Préfixes de clés
const PREFIXES = {
  WEATHER: 'weather',
  PARCELLES: 'parcelles',
  SENSORS: 'sensors',
  MARKETPLACE: 'marketplace',
  USER: 'user',
  FORMATIONS: 'formations',
  REGIONS: 'regions',
  SESSION: 'session'
};

/**
 * Initialise le client Redis
 * @returns {Redis} Client Redis
 */
const initRedis = () => {
  if (!config.redis.enabled) {
    return null;
  }

  if (!redisClient) {
    redisClient = new Redis({
      host: config.redis.host,
      port: config.redis.port,
      password: config.redis.password,
      keyPrefix: 'agrismart:',
      retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      maxRetriesPerRequest: 3,
      enableReadyCheck: true,
      lazyConnect: true
    });

    redisClient.on('connect', () => {
      logger.info('[Cache] Redis Client Connected');
    });

    redisClient.on('ready', () => {
      logger.info('[Cache] Redis Client Ready');
    });

    redisClient.on('error', (err) => {
      logger.error('[Cache] Redis Client Error', { error: err.message });
    });

    redisClient.on('close', () => {
      logger.warn('[Cache] Redis Client Connection Closed');
    });
  }
  return redisClient;
};

/**
 * Compresse les données si elles dépassent le seuil
 * @param {string} data - Données à compresser
 * @returns {Promise<{data: string, compressed: boolean}>}
 */
const compress = async (data) => {
  if (data.length < COMPRESSION_THRESHOLD) {
    return { data, compressed: false };
  }
  
  try {
    const compressed = await gzip(Buffer.from(data));
    return { 
      data: compressed.toString('base64'), 
      compressed: true 
    };
  } catch (error) {
    logger.warn('[Cache] Compression failed', { error: error.message });
    return { data, compressed: false };
  }
};

/**
 * Décompresse les données si nécessaire
 * @param {string} data - Données à décompresser
 * @param {boolean} isCompressed - Si les données sont compressées
 * @returns {Promise<string>}
 */
const decompress = async (data, isCompressed) => {
  if (!isCompressed) {
    return data;
  }
  
  try {
    const buffer = Buffer.from(data, 'base64');
    const decompressed = await gunzip(buffer);
    return decompressed.toString();
  } catch (error) {
    logger.warn('[Cache] Decompression failed', { error: error.message });
    return data;
  }
};

const cache = {
  /**
   * Récupère une valeur du cache
   * @param {string} key - Clé de cache
   * @returns {Promise<any>} Valeur ou null
   */
  get: async (key) => {
    try {
      if (!config.redis.enabled) return null;
      if (!redisClient) initRedis();
      const raw = await redisClient.get(key);
      
      if (!raw) return null;
      
      const parsed = JSON.parse(raw);
      
      // Si les données sont wrappées avec info de compression
      if (parsed && typeof parsed === 'object' && '_compressed' in parsed) {
        const decompressed = await decompress(parsed._data, parsed._compressed);
        return JSON.parse(decompressed);
      }
      
      return parsed;
    } catch (error) {
      logger.warn(`[Cache] Get Error: ${key}`, { error: error.message });
      return null;
    }
  },

  /**
   * Stocke une valeur dans le cache
   * @param {string} key - Clé de cache
   * @param {any} value - Valeur à stocker
   * @param {number} ttlSeconds - TTL en secondes
   */
  set: async (key, value, ttlSeconds = TTL.DEFAULT) => {
    try {
      if (!config.redis.enabled) return;
      if (!redisClient) initRedis();
      
      const stringValue = JSON.stringify(value);
      const { data, compressed } = await compress(stringValue);
      
      // Wrapper avec info de compression
      const toStore = JSON.stringify({
        _compressed: compressed,
        _data: data,
        _cachedAt: new Date().toISOString()
      });
      
      if (ttlSeconds) {
        await redisClient.set(key, toStore, 'EX', ttlSeconds);
      } else {
        await redisClient.set(key, toStore);
      }
      
      logger.debug(`[Cache] Set: ${key}`, { 
        ttl: ttlSeconds, 
        compressed,
        size: toStore.length 
      });
    } catch (error) {
      logger.warn(`[Cache] Set Error: ${key}`, { error: error.message });
    }
  },

  /**
   * Supprime une clé du cache
   * @param {string} key - Clé à supprimer
   */
  del: async (key) => {
    try {
      if (!config.redis.enabled) return;
      if (!redisClient) initRedis();
      await redisClient.del(key);
      logger.debug(`[Cache] Del: ${key}`);
    } catch (error) {
      logger.warn(`[Cache] Del Error: ${key}`, { error: error.message });
    }
  },

  /**
   * Supprime toutes les clés correspondant à un pattern
   * @param {string} pattern - Pattern de clé (ex: "weather:*")
   */
  clearPattern: async (pattern) => {
    try {
      if (!config.redis.enabled) return 0;
      if (!redisClient) initRedis();
      
      const fullPattern = `agrismart:${pattern}`;
      const stream = redisClient.scanStream({
        match: fullPattern,
        count: 100
      });

      let deletedCount = 0;
      
      stream.on('data', async (keys) => {
        if (keys.length) {
          // Enlever le préfixe pour la suppression
          const cleanKeys = keys.map(k => k.replace('agrismart:', ''));
          await redisClient.unlink(...cleanKeys);
          deletedCount += keys.length;
        }
      });

      return new Promise((resolve) => {
        stream.on('end', () => {
          logger.debug(`[Cache] ClearPattern: ${pattern}`, { deleted: deletedCount });
          resolve(deletedCount);
        });
      });
    } catch (error) {
      logger.warn(`[Cache] ClearPattern Error: ${pattern}`, { error: error.message });
      return 0;
    }
  },

  /**
   * Vérifie si une clé existe
   * @param {string} key - Clé à vérifier
   * @returns {Promise<boolean>}
   */
  exists: async (key) => {
    try {
      if (!config.redis.enabled) return false;
      if (!redisClient) initRedis();
      const result = await redisClient.exists(key);
      return result === 1;
    } catch (error) {
      return false;
    }
  },

  /**
   * Récupère ou calcule une valeur (cache-aside pattern)
   * @param {string} key - Clé de cache
   * @param {Function} fetchFn - Fonction pour récupérer la valeur
   * @param {number} ttlSeconds - TTL en secondes
   * @returns {Promise<any>}
   */
  getOrSet: async (key, fetchFn, ttlSeconds = TTL.DEFAULT) => {
    try {
      // Essayer le cache d'abord
      const cached = await cache.get(key);
      if (cached !== null) {
        logger.debug(`[Cache] Hit: ${key}`);
        return cached;
      }

      // Cache miss - récupérer la donnée
      logger.debug(`[Cache] Miss: ${key}`);
      const value = await fetchFn();
      
      // Stocker dans le cache si la valeur existe
      if (value !== null && value !== undefined) {
        await cache.set(key, value, ttlSeconds);
      }
      
      return value;
    } catch (error) {
      logger.warn(`[Cache] GetOrSet Error: ${key}`, { error: error.message });
      // En cas d'erreur cache, retourner directement la donnée
      return fetchFn();
    }
  },

  // ============================
  // Méthodes spécialisées
  // ============================

  /**
   * Cache météo
   */
  weather: {
    get: (lat, lon) => cache.get(`${PREFIXES.WEATHER}:${lat}:${lon}`),
    set: (lat, lon, data) => cache.set(`${PREFIXES.WEATHER}:${lat}:${lon}`, data, TTL.WEATHER),
    getForecast: (lat, lon) => cache.get(`${PREFIXES.WEATHER}:forecast:${lat}:${lon}`),
    setForecast: (lat, lon, data) => cache.set(`${PREFIXES.WEATHER}:forecast:${lat}:${lon}`, data, TTL.WEATHER_FORECAST),
    invalidate: (lat, lon) => cache.del(`${PREFIXES.WEATHER}:${lat}:${lon}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.WEATHER}:*`)
  },

  /**
   * Cache parcelles
   */
  parcelles: {
    getByUser: (userId) => cache.get(`${PREFIXES.PARCELLES}:user:${userId}`),
    setByUser: (userId, data) => cache.set(`${PREFIXES.PARCELLES}:user:${userId}`, data, TTL.PARCELLES),
    getById: (id) => cache.get(`${PREFIXES.PARCELLES}:${id}`),
    setById: (id, data) => cache.set(`${PREFIXES.PARCELLES}:${id}`, data, TTL.PARCELLES),
    invalidateUser: (userId) => cache.del(`${PREFIXES.PARCELLES}:user:${userId}`),
    invalidateById: (id) => cache.del(`${PREFIXES.PARCELLES}:${id}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.PARCELLES}:*`)
  },

  /**
   * Cache capteurs
   */
  sensors: {
    getData: (capteurId) => cache.get(`${PREFIXES.SENSORS}:${capteurId}`),
    setData: (capteurId, data) => cache.set(`${PREFIXES.SENSORS}:${capteurId}`, data, TTL.SENSORS),
    getByParcelle: (parcelleId) => cache.get(`${PREFIXES.SENSORS}:parcelle:${parcelleId}`),
    setByParcelle: (parcelleId, data) => cache.set(`${PREFIXES.SENSORS}:parcelle:${parcelleId}`, data, TTL.SENSORS),
    invalidate: (capteurId) => cache.del(`${PREFIXES.SENSORS}:${capteurId}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.SENSORS}:*`)
  },

  /**
   * Cache marketplace
   */
  marketplace: {
    getProducts: (page = 1, filters = '') => cache.get(`${PREFIXES.MARKETPLACE}:products:${page}:${filters}`),
    setProducts: (page, filters, data) => cache.set(`${PREFIXES.MARKETPLACE}:products:${page}:${filters}`, data, TTL.MARKETPLACE),
    getProduct: (id) => cache.get(`${PREFIXES.MARKETPLACE}:product:${id}`),
    setProduct: (id, data) => cache.set(`${PREFIXES.MARKETPLACE}:product:${id}`, data, TTL.MARKETPLACE),
    invalidateProduct: (id) => cache.del(`${PREFIXES.MARKETPLACE}:product:${id}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.MARKETPLACE}:*`)
  },

  /**
   * Cache utilisateur
   */
  user: {
    getProfile: (userId) => cache.get(`${PREFIXES.USER}:profile:${userId}`),
    setProfile: (userId, data) => cache.set(`${PREFIXES.USER}:profile:${userId}`, data, TTL.USER_PROFILE),
    invalidateProfile: (userId) => cache.del(`${PREFIXES.USER}:profile:${userId}`)
  },

  /**
   * Cache régions (données statiques)
   */
  regions: {
    getAll: () => cache.get(`${PREFIXES.REGIONS}:all`),
    setAll: (data) => cache.set(`${PREFIXES.REGIONS}:all`, data, TTL.REGIONS),
    getById: (id) => cache.get(`${PREFIXES.REGIONS}:${id}`),
    setById: (id, data) => cache.set(`${PREFIXES.REGIONS}:${id}`, data, TTL.REGIONS)
  },

  // Constantes exportées
  TTL,
  PREFIXES,
  
  // Client Redis brut si nécessaire
  getClient: () => {
    if (!config.redis.enabled) return null;
    if (!redisClient) initRedis();
    return redisClient;
  }
};

module.exports = cache;
