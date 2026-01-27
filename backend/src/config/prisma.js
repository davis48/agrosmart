// Charger le bon fichier .env selon l'environnement
const path = require('path');
const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
require('dotenv').config({ path: path.resolve(__dirname, '../../', envFile) });

const { PrismaClient } = require('@prisma/client');

// Singleton instance - Prisma 5.x with native mysql2 driver
let prisma;

if (process.env.NODE_ENV === 'production') {
    prisma = new PrismaClient({
        log: ['error', 'warn'],
    });
} else {
    // In development, use a global variable to preserve the instance across hot-reloads
    if (!global.prisma) {
        global.prisma = new PrismaClient({
            log: ['query', 'error', 'warn'],
        });
    }
    prisma = global.prisma;
}

// Graceful shutdown helpers
const cleanup = async () => {
    if (prisma) await prisma.$disconnect();
};

process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);

module.exports = prisma;
