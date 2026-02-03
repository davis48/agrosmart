/**
 * Routes principales - Agrégation de toutes les routes
 * AgriSmart CI - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();

// Import des routes
console.log('🔵 routes/index: Loading authRoutes...');
const authRoutes = require('./auth');
console.log('🔵 routes/index: Loading usersRoutes...');
const usersRoutes = require('./users');
console.log('🔵 routes/index: Loading regionsRoutes...');
const regionsRoutes = require('./regions');
console.log('🔵 routes/index: Loading parcellesRoutes...');
const parcellesRoutes = require('./parcelles');
console.log('🔵 routes/index: Loading capteursRoutes...');
const capteursRoutes = require('./capteurs');
console.log('🔵 routes/index: Loading mesuresRoutes...');
const mesuresRoutes = require('./mesures');
console.log('🔵 routes/index: Loading alertesRoutes...');
const alertesRoutes = require('./alertes');
console.log('🔵 routes/index: Loading culturesRoutes...');
const culturesRoutes = require('./cultures');
console.log('🔵 routes/index: Loading maladiesRoutes...');
const maladiesRoutes = require('./maladies');
console.log('🔵 routes/index: Loading recommandationsRoutes...');
const recommandationsRoutes = require('./recommandations');
console.log('🔵 routes/index: Loading marketplaceRoutes...');
const marketplaceRoutes = require('./marketplace');
console.log('🔵 routes/index: Loading formationsRoutes...');
const formationsRoutes = require('./formations');
console.log('🔵 routes/index: Loading messagesRoutes...');
const messagesRoutes = require('./messages');
console.log('🔵 routes/index: Loading weatherRoutes...');
const weatherRoutes = require('./weather');
console.log('🔵 routes/index: Loading analyticsRoutes...');
const analyticsRoutes = require('./analytics');
console.log('🔵 routes/index: Loading diagnosticsRoutes...');
const diagnosticsRoutes = require('./diagnostics');
console.log('🔵 routes/index: Loading adminRoutes...');
const adminRoutes = require('./admin');
console.log('🔵 routes/index: Loading dashboardRoutes...');
const dashboardRoutes = require('./dashboard');
console.log('🔵 routes/index: Loading communauteRoutes...');
const communauteRoutes = require('./communaute');
console.log('🔵 routes/index: Loading chatRoutes...');
const chatRoutes = require('./chat');
console.log('🔵 routes/index: Loading chatbotRoutes...');
const chatbotRoutes = require('./chatbot');
console.log('🔵 routes/index: Loading smsRoutes...');
const smsRoutes = require('./sms');
console.log('🔵 routes/index: Loading gamificationRoutes...');
const gamificationRoutes = require('./gamification');
console.log('🔵 routes/index: Loading groupPurchasesRoutes...');
const groupPurchasesRoutes = require('./groupPurchases');
console.log('🔵 routes/index: Loading paymentsRoutes...');
const paymentsRoutes = require('./payments');
console.log('🔵 routes/index: Loading cartRoutes...');
const cartRoutes = require('./cart');
console.log('🔵 routes/index: Loading favoritesRoutes...');
const favoritesRoutes = require('./favorites');
console.log('🔵 routes/index: Loading stocksRoutes...');
// TEMPORARILY DISABLED - BLOCKS STARTUP
// const stocksRoutes = require('./stocks');
console.log('🔵 routes/index: stocksRoutes SKIPPED (debugging)');
console.log('🔵 routes/index: Loading calendrierRoutes...');
// TEMPORARILY DISABLED - BLOCKS STARTUP
// const calendrierRoutes = require('./calendrier');
console.log('🔵 routes/index: calendrierRoutes SKIPPED (debugging)');
console.log('🔵 routes/index: All routes loaded!');

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
router.use('/cart', cartRoutes);
router.use('/favorites', favoritesRoutes);
// router.use('/stocks', stocksRoutes); // Temporarily disabled - blocks startup
// router.use('/calendrier', calendrierRoutes); // Temporarily disabled - blocks startup

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
      diagnostics: '/api/diagnostics',
      stocks: '/api/stocks',
      calendrier: '/api/calendrier'
    }
  });
});

module.exports = router;
