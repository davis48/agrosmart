/**
 * Routes principales - Agrégation de toutes les routes
 * AgriSmart CI - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();

// Import des routes
const authRoutes = require('./auth');
const usersRoutes = require('./users');
const regionsRoutes = require('./regions');
const parcellesRoutes = require('./parcelles');
const capteursRoutes = require('./capteurs');
const mesuresRoutes = require('./mesures');
const alertesRoutes = require('./alertes');
const culturesRoutes = require('./cultures');
const maladiesRoutes = require('./maladies');
const recommandationsRoutes = require('./recommandations');
const marketplaceRoutes = require('./marketplace');
const formationsRoutes = require('./formations');
const messagesRoutes = require('./messages');
const weatherRoutes = require('./weather');
const analyticsRoutes = require('./analytics');
const diagnosticsRoutes = require('./diagnostics');
const adminRoutes = require('./admin');
const dashboardRoutes = require('./dashboard');
const communauteRoutes = require('./communaute');
const chatRoutes = require('./chat');
const chatbotRoutes = require('./chatbot');
const smsRoutes = require('./sms');
const gamificationRoutes = require('./gamification');
const groupPurchasesRoutes = require('./groupPurchases');
const paymentsRoutes = require('./payments');

// Montage des routes
router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/regions', regionsRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/communaute', communauteRoutes);
router.use('/parcelles', parcellesRoutes);
router.use('/capteurs', capteursRoutes);
router.use('/mesures', mesuresRoutes);
router.use('/alertes', alertesRoutes);
router.use('/cultures', culturesRoutes);
router.use('/maladies', maladiesRoutes);
router.use('/recommandations', recommandationsRoutes);
router.use('/marketplace', marketplaceRoutes);
router.use('/formations', formationsRoutes);
router.use('/messages', messagesRoutes);
router.use('/weather', weatherRoutes);
// Note: /meteo supprimé - utiliser /weather uniquement pour éviter la duplication
router.use('/analytics', analyticsRoutes);
router.use('/diagnostics', diagnosticsRoutes);
router.use('/admin', adminRoutes);
router.use('/chat', chatRoutes);
router.use('/chatbot', chatbotRoutes);
router.use('/sms', smsRoutes);
router.use('/gamification', gamificationRoutes);
router.use('/group-purchases', groupPurchasesRoutes);
router.use('/payments', paymentsRoutes);

// Route de health check
router.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: '1.0.0'
  });
});

// Route d'information de l'API
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Bienvenue sur l\'API AgriSmart CI',
    version: '1.0.0',
    documentation: '/api/docs',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      parcelles: '/api/parcelles',
      capteurs: '/api/capteurs',
      mesures: '/api/mesures',
      alertes: '/api/alertes',
      cultures: '/api/cultures',
      maladies: '/api/maladies',
      recommandations: '/api/recommandations',
      marketplace: '/api/marketplace',
      formations: '/api/formations',
      messages: '/api/messages',
      weather: '/api/weather',
      analytics: '/api/analytics',
      diagnostics: '/api/diagnostics'
    }
  });
});

module.exports = router;
