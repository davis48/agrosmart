/**
 * Rate Limiting avancé par endpoint
 * AgriSmart CI - Système Agricole Intelligent
 * 
 * Ce module fournit des limiteurs de débit spécifiques:
 * - Login: Protection contre les attaques brute-force
 * - Register: Limite les créations de comptes
 * - OTP: Protection contre le spam de codes
 * - API générale: Limite globale par IP
 * - Upload: Limite les téléchargements de fichiers
 * 
 * @module middlewares/rateLimiter
 */

const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const Redis = require('ioredis');
const config = require('../config');
const logger = require('../utils/logger');

// Client Redis pour le rate limiting (partagé)
let redisClient = null;

/**
 * Initialise le client Redis pour le rate limiting
 * @returns {Redis} Client Redis
 */
const getRedisClient = () => {
  if (!redisClient) {
    redisClient = new Redis({
      host: config.redis.host,
      port: config.redis.port,
      password: config.redis.password,
      keyPrefix: 'rl:',
      retryStrategy: (times) => Math.min(times * 50, 2000)
    });
    
    redisClient.on('error', (err) => {
      logger.error('Rate Limiter Redis Error:', err.message);
    });
  }
  return redisClient;
};

/**
 * Crée un store Redis pour le rate limiting
 * @param {string} prefix - Préfixe pour les clés
 * @returns {RedisStore|undefined} Store Redis ou undefined (fallback mémoire)
 */
const createRedisStore = (prefix) => {
  try {
    return new RedisStore({
      sendCommand: (...args) => getRedisClient().call(...args),
      prefix: `rl:${prefix}:`
    });
  } catch (error) {
    logger.warn(`Redis store creation failed for ${prefix}, using memory store`);
    return undefined;
  }
};

/**
 * Handler personnalisé pour les erreurs de rate limit
 * @param {Request} req 
 * @param {Response} res 
 * @param {NextFunction} next 
 * @param {Object} options 
 */
const rateLimitHandler = (req, res, next, options) => {
  logger.warn(`Rate limit exceeded`, {
    ip: req.ip,
    path: req.path,
    method: req.method,
    userAgent: req.get('User-Agent'),
    limitType: options.limitType || 'general'
  });
  
  res.status(429).json({
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: options.message || 'Trop de requêtes, veuillez réessayer plus tard.',
      retryAfter: Math.ceil(options.windowMs / 1000)
    }
  });
};

/**
 * Rate limiter pour la connexion (Login)
 * - 5 tentatives par 15 minutes par IP
 * - Bloque les attaques brute-force
 */
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 tentatives max
  message: 'Trop de tentatives de connexion. Réessayez dans 15 minutes.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('login'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => {
    // Combine IP + email pour un tracking plus précis
    const email = req.body?.email || req.body?.telephone || 'unknown';
    const ip = req.ip || req.socket?.remoteAddress || '127.0.0.1';
    return `${ip}:${email}`;
  },
  skip: (req) => {
    // Ne pas limiter en mode test
    return config.isTest;
  },
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'login' });
  }
});

/**
 * Rate limiter pour l'inscription (Register)
 * - 3 créations de compte par heure par IP
 * - Prévient le spam de comptes
 */
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 3, // 3 inscriptions max par heure
  message: 'Trop de créations de compte. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('register'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => req.ip || req.socket?.remoteAddress || '127.0.0.1',
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'register' });
  }
});

/**
 * Rate limiter pour les OTP
 * - 5 demandes par 10 minutes par téléphone
 * - Prévient le spam SMS coûteux
 */
const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 5, // 5 demandes max
  message: 'Trop de demandes de code OTP. Réessayez dans 10 minutes.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('otp'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => {
    const phone = req.body?.telephone || req.params?.telephone || 'unknown';
    const ip = req.ip || req.socket?.remoteAddress || '127.0.0.1';
    return `${ip}:${phone}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'otp' });
  }
});

/**
 * Rate limiter pour la vérification OTP
 * - 10 vérifications par 5 minutes
 * - Empêche le brute-force des codes
 */
const otpVerifyLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 10, // 10 essais max
  message: 'Trop de tentatives de vérification. Réessayez dans 5 minutes.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('otp-verify'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => {
    const phone = req.body?.telephone || 'unknown';
    const ip = req.ip || req.socket?.remoteAddress || '127.0.0.1';
    return `${ip}:${phone}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'otp-verify' });
  }
});

/**
 * Rate limiter pour les uploads
 * - 20 uploads par heure par utilisateur
 * - Protège le stockage et la bande passante
 */
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 20, // 20 uploads max
  message: 'Trop de fichiers téléchargés. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('upload'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => {
    const userId = req.user?.id || req.ip || req.socket?.remoteAddress || '127.0.0.1';
    return `upload:${userId}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'upload' });
  }
});

/**
 * Rate limiter pour le diagnostic IA
 * - 10 diagnostics par heure par utilisateur
 * - Protège le service IA des surcharges
 */
const diagnosticLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 10, // 10 diagnostics max
  message: 'Trop de diagnostics demandés. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('diagnostic'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => {
    const userId = req.user?.id || req.ip || req.socket?.remoteAddress || '127.0.0.1';
    return `diag:${userId}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'diagnostic' });
  }
});

/**
 * Rate limiter pour les requêtes API générales
 * - 100 requêtes par minute par IP
 * - Protection DDoS basique
 */
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requêtes max
  message: 'Trop de requêtes. Veuillez patienter.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('api'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => req.ip || req.socket?.remoteAddress || '127.0.0.1',
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'api' });
  }
});

/**
 * Rate limiter strict pour les endpoints sensibles
 * - 30 requêtes par minute
 * - Pour les endpoints critiques
 */
const strictLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // 30 requêtes max
  message: 'Limite de requêtes atteinte pour cette ressource.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('strict'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => {
    const userId = req.user?.id || req.ip || req.socket?.remoteAddress || '127.0.0.1';
    return `strict:${userId}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'strict' });
  }
});

/**
 * Rate limiter pour le mot de passe oublié
 * - 3 demandes par heure par email
 */
const passwordResetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 3, // 3 demandes max
  message: 'Trop de demandes de réinitialisation. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createRedisStore('pwd-reset'),
  validate: { xForwardedForHeader: false, ip: false },
  keyGenerator: (req) => {
    const email = req.body?.email || 'unknown';
    const ip = req.ip || req.socket?.remoteAddress || '127.0.0.1';
    return `${ip}:${email}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'password-reset' });
  }
});

module.exports = {
  loginLimiter,
  registerLimiter,
  otpLimiter,
  otpVerifyLimiter,
  uploadLimiter,
  diagnosticLimiter,
  apiLimiter,
  strictLimiter,
  passwordResetLimiter,
  getRedisClient
};
