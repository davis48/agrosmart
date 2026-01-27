/**
 * Jest Configuration - AgriSmart CI Backend
 * 
 * Configuration pour les tests unitaires et d'intégration
 */

module.exports = {
  // Environnement de test
  testEnvironment: 'node',

  // Timeout global (30 secondes pour les tests d'intégration)
  testTimeout: 30000,

  // Patterns de fichiers de test
  testMatch: [
    '**/tests/**/*.test.js',
    '**/tests/**/*.spec.js'
  ],

  // Ignorer node_modules et build
  testPathIgnorePatterns: [
    '/node_modules/',
    '/build/',
    '/dist/'
  ],

  // Couverture de code
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/config/*.js',
    '!src/**/*.test.js'
  ],

  // Setup avant les tests
  setupFilesAfterEnv: ['./tests/setup.js'],

  // Variables d'environnement
  testEnvironmentOptions: {
    NODE_ENV: 'test'
  },

  // Verbose output
  verbose: true,

  // Force exit after tests (important pour les tests avec DB)
  forceExit: true,

  // Detect open handles
  detectOpenHandles: true,

  // Projets de test séparés
  projects: [
    {
      displayName: 'unit',
      testMatch: ['<rootDir>/tests/unit/**/*.test.js'],
      testEnvironment: 'node'
    },
    {
      displayName: 'integration',
      testMatch: ['<rootDir>/tests/integration/**/*.test.js'],
      testEnvironment: 'node',
      // Les tests d'intégration peuvent être ignorés en CI
      ...(process.env.SKIP_INTEGRATION_TESTS === 'true' && {
        testMatch: []
      })
    },
    {
      displayName: 'security',
      testMatch: [
        '<rootDir>/tests/security.test.js',
        '<rootDir>/tests/auth-security.test.js'
      ],
      testEnvironment: 'node',
      // Les tests de sécurité nécessitent une DB
      ...(process.env.SKIP_DB_TESTS === 'true' && {
        testMatch: []
      })
    },
    {
      displayName: 'functional',
      testMatch: [
        '<rootDir>/tests/functional.test.js',
        '<rootDir>/tests/migration_verification.test.js'
      ],
      testEnvironment: 'node',
      // Les tests fonctionnels nécessitent une DB
      ...(process.env.SKIP_DB_TESTS === 'true' && {
        testMatch: []
      })
    }
  ]
};
