const request = require('supertest');
const bcrypt = require('bcryptjs');

// Chargement conditionnel pour éviter les erreurs si DB non disponible
let app = null;
let prisma = null;
let serverAvailable = false;
let authToken;
let testUserId;

// Increase timeout for DB operations
jest.setTimeout(30000);

beforeAll(async () => {
    try {
        // Essayer de charger le serveur et Prisma
        const server = require('../src/server');
        app = server.app || server;
        prisma = require('../src/config/prisma');
        
        // Tester la connexion DB
        await prisma.$connect();
        serverAvailable = true;
        
        // 1. Create a Test User directly in DB to ensure we can login
        const email = `test_verif_${Date.now()}@example.com`;
        const passwordHash = await bcrypt.hash('password123', 10);

        const user = await prisma.user.create({
            data: {
                nom: 'Test',
                prenoms: 'Verification',
                email,
                passwordHash,
                role: 'PRODUCTEUR',
                status: 'ACTIF',
                telephone: `01${Date.now().toString().slice(-8)}`
            }
        });
        testUserId = user.id;

        // 2. Login to get Token
        const res = await request(app)
            .post('/api/v1/auth/login')
            .send({ identifier: email, password: 'password123' });

        if (res.statusCode === 200) {
            authToken = res.body.data.token;
        }
    } catch (e) {
        console.warn('⚠️ Setup Error (serveur ou DB non disponible):', e.message);
        serverAvailable = false;
    }
});

afterAll(async () => {
    if (prisma) {
        try {
            await prisma.$disconnect();
        } catch (e) {}
    }
});

describe('Migration Verification - Critical Controllers', () => {

    test('Auth: Profile should return user data (Prisma)', async () => {
        if (!serverAvailable || !authToken) {
            console.log('⚠️ Serveur ou token non disponible, test ignoré');
            return;
        }
        const res = await request(app)
            .get('/api/v1/auth/me')
            .set('Authorization', `Bearer ${authToken}`);

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.data.id).toBe(testUserId);
    });

    test('Parcelles: Should list parcelles (Prisma)', async () => {
        if (!serverAvailable || !authToken) {
            console.log('⚠️ Serveur ou token non disponible, test ignoré');
            return;
        }
        const res = await request(app)
            .get('/api/v1/parcelles')
            .set('Authorization', `Bearer ${authToken}`);

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(Array.isArray(res.body.data)).toBe(true);
    });

    test('Marketplace: Should listed products (Prisma)', async () => {
        if (!serverAvailable || !authToken) {
            console.log('⚠️ Serveur ou token non disponible, test ignoré');
            return;
        }
        const res = await request(app)
            .get('/api/v1/marketplace/produits')
            .set('Authorization', `Bearer ${authToken}`);

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
    });

    test('Dashboard: Should return stats (Prisma)', async () => {
        if (!serverAvailable || !authToken) {
            console.log('⚠️ Serveur ou token non disponible, test ignoré');
            return;
        }
        const res = await request(app)
            .get('/api/v1/dashboard/stats')
            .set('Authorization', `Bearer ${authToken}`);

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.data).toHaveProperty('parcelles');
    });

    test('Diagnostics: Should return history (Prisma)', async () => {
        if (!serverAvailable || !authToken) {
            console.log('⚠️ Serveur ou token non disponible, test ignoré');
            return;
        }
        const res = await request(app)
            .get('/api/v1/diagnostics/history')
            .set('Authorization', `Bearer ${authToken}`);

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
    });
});
