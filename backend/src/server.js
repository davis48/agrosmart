/**
 * Point d'entrée principal du serveur
 * AgroSmart - Système Agricole Intelligent
 */

const path = require('path');
const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
require('dotenv').config({ path: path.resolve(__dirname, '../', envFile) });

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const http = require('http');

const config = require('./config');
const { closePool } = require('./config/database');
const logger = require('./utils/logger');
const errorHandler = require('./middlewares/errorHandler');
const socket = require('./socket');
const routes = require('./routes');
const { setupSwagger } = require('./config/swagger');
const prisma = require('./config/prisma');

// Création de l'application Express
const app = express();
const server = http.createServer(app);

// =====================================================
// MIDDLEWARES DE SÉCURITÉ
// =====================================================

app.use(helmet({
  contentSecurityPolicy: config.isProd,
  crossOriginEmbedderPolicy: false
}));

/**
 * Configuration CORS
 * - Dev : Autorise toutes les origines
 * - Prod : Whitelist stricte via ALLOWED_ORIGINS
 */
const allowedOrigins = config.isProd
  ? (process.env.ALLOWED_ORIGINS || '').split(',').filter(Boolean)
  : '*';

app.use(cors({
  origin: (origin, callback) => {
    if (!config.isProd || allowedOrigins === '*') {
      return callback(null, true);
    }
    if (!origin) {
      return callback(null, true);
    }
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    logger.warn(`CORS: Origine non autorisée bloquée: ${origin}`);
    callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
  credentials: true
}));

// Rate limiting global (désactivé en mode test)
if (process.env.NODE_ENV !== 'test') {
  const limiter = rateLimit({
    windowMs: config.rateLimit.windowMs,
    max: config.rateLimit.maxRequests,
    message: {
      success: false,
      message: 'Trop de requêtes, veuillez réessayer plus tard.',
      code: 'RATE_LIMIT_EXCEEDED'
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
      logger.warn(`Rate limit exceeded for IP: ${req.ip}`);
      res.status(options.statusCode).send(options.message);
    }
  });
  app.use('/api/v1/', limiter);
}

// Initialisation Socket.IO
const io = socket.init(server);
app.set('io', io);

// Rate limiting spécifique pour l'authentification (désactivé en mode test)
if (process.env.NODE_ENV !== 'test') {
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: {
      success: false,
      message: 'Trop de tentatives de connexion, veuillez réessayer dans 15 minutes.',
      code: 'AUTH_RATE_LIMIT_EXCEEDED'
    }
  });
  app.use('/api/v1/auth/login', authLimiter);
  app.use('/api/v1/auth/otp', authLimiter);
}

// =====================================================
// MIDDLEWARES GÉNÉRAUX
// =====================================================

app.use(compression());

const { securityMiddleware, bruteForceProtection } = require('./middlewares/security');
app.use(securityMiddleware());
app.use('/api/v1/auth/login', bruteForceProtection());
app.use('/api/v1/auth/otp', bruteForceProtection());

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// =====================================================
// DOCUMENTATION API (Swagger)
// =====================================================

if (!config.isTest) {
  setupSwagger(app);
}

// =====================================================
// ROUTES - Point de montage unique
// =====================================================

app.use('/api/v1', routes);

// Health check racine
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// =====================================================
// GESTION DES ERREURS
// =====================================================

app.use(errorHandler);

// Fonctions utilitaires Socket.IO
app.set('emitAlert', (userId, alert) => {
  io.to(`user:${userId}`).emit('alert:new', alert);
});

app.set('emitMeasurement', (parcelleId, measurement) => {
  io.to(`parcelle:${parcelleId}`).emit('measurement:new', measurement);
});

// =====================================================
// DÉMARRAGE DU SERVEUR
// =====================================================

const startServer = async () => {
  try {
    await prisma.$connect();
    logger.info('Prisma connected to MySQL successfully');

    server.listen(config.server.port, () => {
      logger.info(`AgroSmart Backend démarré`);
      logger.info(`Port: ${config.server.port}`);
      logger.info(`Environnement: ${config.env}`);
      logger.info(`API Version: ${config.server.apiVersion}`);
      logger.info(`URL: http://localhost:${config.server.port}`);
    });
  } catch (error) {
    logger.error('Erreur au démarrage du serveur', { error: error.message });
    process.exit(1);
  }
};

// =====================================================
// ARRÊT GRACIEUX
// =====================================================

const gracefulShutdown = async (signal) => {
  logger.info(`Signal ${signal} reçu, arrêt en cours...`);
  server.close(() => logger.info('Serveur HTTP fermé'));
  io.close(() => logger.info('Connexions WebSocket fermées'));
  await closePool();
  process.exit(0);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('uncaughtException', (error) => {
  logger.error('Exception non capturée', { error: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Promesse rejetée non gérée', { reason });
});

if (require.main === module) {
  startServer();
}

module.exports = { app, server, io };
