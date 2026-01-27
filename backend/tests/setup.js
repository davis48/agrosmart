/**
 * Jest Setup - AgriSmart CI Backend
 * 
 * Configuration globale pour tous les tests
 */

// Augmenter le timeout pour les tests d'intégration
jest.setTimeout(30000);

// Désactiver les logs pendant les tests (sauf erreurs)
if (process.env.JEST_SILENT !== 'false') {
  global.console = {
    ...console,
    log: jest.fn(),
    info: jest.fn(),
    debug: jest.fn(),
    // Garder warn et error
    warn: console.warn,
    error: console.error,
  };
}

// Vérifier si la DB est disponible avant les tests qui en ont besoin
global.checkDatabaseConnection = async () => {
  try {
    const prisma = require('../src/config/prisma');
    await prisma.$connect();
    return true;
  } catch (error) {
    console.warn('⚠️ Base de données non disponible:', error.message);
    return false;
  }
};

// Helper pour skip les tests si la DB n'est pas disponible
global.skipIfNoDb = (testFn) => {
  return async () => {
    const dbAvailable = await global.checkDatabaseConnection();
    if (!dbAvailable) {
      console.warn('⏭️ Test ignoré - DB non disponible');
      return;
    }
    return testFn();
  };
};

// Cleanup après tous les tests
afterAll(async () => {
  try {
    const prisma = require('../src/config/prisma');
    await prisma.$disconnect();
  } catch (e) {
    // Ignorer les erreurs de déconnexion
  }
});
