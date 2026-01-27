/**
 * Point d'entrée principal du serveur
 * AgriSmart CI - Système Agricole Intelligent
 */

// Charger le bon fichier .env selon l'environnement
const path = require('path'); // Added path module
const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
require('dotenv').config({ path: path.resolve(__dirname, '../', envFile) });

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
// const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const http = require('http'); // Changed from { createServer } to http

const config = require('./config');
const { closePool } = require('./config/database');
const logger = require('./utils/logger');
const errorHandler = require('./middlewares/errorHandler');
const socket = require('./socket'); // New socket module import
const routes = require('./routes');
const uploadRoutes = require('./routes/upload'); // Import Upload routes
const { setupSwagger } = require('./config/swagger'); // Swagger docs
// const authRoutes = require('./routes/auth');
const parcelles = require('./routes/parcelles');
// sensors route does not exist - removed
const alertes = require('./routes/alertes');
const marketplace = require('./routes/marketplace');
const messages = require('./routes/messages');
const formations = require('./routes/formations');
const weather = require('./routes/weather');
const prisma = require('./config/prisma');

// Création de l'application Express
const app = express();
const server = http.createServer(app); // Changed httpServer to server and used http.createServer

// Configuration Socket.IO pour les alertes temps réel
// const io = new Server(httpServer, { // Original io initialization removed
//   cors: {
//     origin: '*',
//     methods: ['GET', 'POST']
//   }
// });

// Middleware global pour injecter io
// app.set('io', io); // Original io injection removed

// =====================================================
// MIDDLEWARES DE SÉCURITÉ
// =====================================================

// Protection des headers HTTP
app.use(helmet({
  contentSecurityPolicy: config.isProd,
  crossOriginEmbedderPolicy: false
}));

/**
 * Configuration CORS (Cross-Origin Resource Sharing)
 * 
 * SÉCURITÉ:
 * - En développement : Autorise toutes les origines (*) pour faciliter le dev
 * - En production : Whitelist stricte des domaines autorisés via ALLOWED_ORIGINS
 * 
 * Variable d'environnement ALLOWED_ORIGINS:
 * Format: Liste séparée par des virgules
 * Exemple: "https://agrismart-ci.com,https://www.agrismart-ci.com,https://admin.agrismart-ci.com"
 */
const allowedOrigins = config.isProd
  ? (process.env.ALLOWED_ORIGINS || '').split(',').filter(Boolean)
  : '*';

app.use(cors({
  origin: (origin, callback) => {
    // Autoriser toutes les origines en développement
    if (!config.isProd || allowedOrigins === '*') {
      return callback(null, true);
    }

    // Autoriser les requêtes sans origine (ex: mobile apps, Postman)
    if (!origin) {
      return callback(null, true);
    }

    // Vérifier si l'origine est dans la whitelist
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    // Rejeter l'origine non autorisée
    logger.warn(`CORS: Origine non autorisée bloquée: ${origin}`);
    callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
  credentials: true
}));

// Rate limiting
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

// Init Socket.io
const io = socket.init(server); // Initialize socket.io with the server
app.set('io', io); // Set io on app after initialization

// Rate limiting spécifique pour l'authentification
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 tentatives
  message: {
    success: false,
    message: 'Trop de tentatives de connexion, veuillez réessayer dans 15 minutes.',
    code: 'AUTH_RATE_LIMIT_EXCEEDED'
  }
});
app.use('/api/v1/auth/login', authLimiter);
app.use('/api/v1/auth/otp', authLimiter);

// =====================================================
// MIDDLEWARES GÉNÉRAUX
// =====================================================

// Compression des réponses
app.use(compression());

// Middlewares de sécurité avancée
const { 
  securityMiddleware, 
  bruteForceProtection 
} = require('./middlewares/security');

// Appliquer les middlewares de sécurité
app.use(securityMiddleware());

// Protection brute-force pour l'authentification
app.use('/api/v1/auth/login', bruteForceProtection());
app.use('/api/v1/auth/otp', bruteForceProtection());

// Parsing JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Servir les fichiers statiques (uploads)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// =====================================================
// DOCUMENTATION API (Swagger)
// =====================================================
if (!config.isTest) {
  setupSwagger(app);
}

// =====================================================
// ROUTES
// =====================================================

app.use('/api/v1', routes);
app.use('/api/upload', uploadRoutes); // Use upload routes
// app.use('/api/auth', authRoutes); // REMOVED - Already mounted in routes/index.js
app.use('/api/parcelles', parcelles);
app.use('/api/alertes', alertes);
app.use('/api/marketplace', marketplace);
app.use('/api/messages', messages);
app.use('/api/formations', formations);
app.use('/api/weather', weather);

// Route de santé
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Middleware de gestion des erreurs
app.use(errorHandler);

// Écoute des événements Socket.io (via module socket)
// Les événements sont gérés dans src/socket.js

// Écoute des événements système pour les notifications temps réel
// Exemple: app.on('alert:new', (alert) => io.emit('alert:new', alert));
// Note: Dans une architecture distribuée, utiliser Redis Pub/Sub

// Fonction pour émettre des alertes depuis le worker ou autre
app.set('emitAlert', (userId, alert) => {
  io.to(`user:${userId}`).emit('alert:new', alert);
});

// Fonction pour émettre des mises à jour de mesures
app.set('emitMeasurement', (parcelleId, measurement) => {
  io.to(`parcelle:${parcelleId}`).emit('measurement:new', measurement);
});

// =====================================================
// DÉMARRAGE DU SERVEUR
// =====================================================

const startServer = async () => {
  try {
    // Vérification de la connexion à la base de données DISABLED - Using Prisma instead
    // const dbConnected = await checkConnection();
    // if (!dbConnected) {
    //   logger.error('Impossible de se connecter à la base de données');
    //   process.exit(1);
    // }

    // Test Prisma connection
    await prisma.$connect();
    logger.info('✅ Prisma connected to MySQL successfully');

    // Initialisation du worker IoT
    const { initWorker } = require('./workers/sensorWorker');
    initWorker();

    // Démarrage du serveur
    server.listen(config.server.port, () => {
      logger.info(`🌱 AgriSmart CI Backend démarré`);
      logger.info(`📡 Port: ${config.server.port}`);
      logger.info(`🌍 Environnement: ${config.env}`);
      logger.info(`📚 API Version: ${config.server.apiVersion}`);
      logger.info(`🔗 URL: http://localhost:${config.server.port}`);
    });

  } catch (error) {
    logger.error('Erreur au démarrage du serveur', { error: error.message });
    process.exit(1);
  }
};

// =====================================================
// GESTION DE L'ARRÊT
// =====================================================

const gracefulShutdown = async (signal) => {
  logger.info(`Signal ${signal} reçu, arrêt en cours...`);

  // Fermer le serveur HTTP
  server.close(() => {
    logger.info('Serveur HTTP fermé');
  });

  // Fermer les connexions WebSocket
  io.close(() => {
    logger.info('Connexions WebSocket fermées');
  });

  // Fermer le pool de connexions DB
  await closePool();

  process.exit(0);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Gestion des erreurs non capturées
process.on('uncaughtException', (error) => {
  logger.error('Exception non capturée', { error: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Promesse rejetée non gérée', { reason });
});

// Démarrage si exécuté directement
if (require.main === module) {
  startServer();
}

module.exports = { app, server, io };
