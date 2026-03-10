/**
 * Charge les variables d'environnement une seule fois pour éviter
 * les relectures multiples de dotenv dans les différents modules.
 */
const path = require('path');

if (!global.__agrosmartEnvLoaded) {
  const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';

  require('dotenv').config({
    path: path.resolve(__dirname, '../../', envFile),
    quiet: true
  });

  global.__agrosmartEnvLoaded = true;
}

module.exports = true;
