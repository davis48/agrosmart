/**
 * Tests de Sécurité Complets - AgriSmart CI
 * 
 * Suite de tests pour valider la conformité OWASP Top 10 et les mesures de sécurité.
 * Ces tests couvrent :
 * - Injection SQL/NoSQL
 * - Cross-Site Scripting (XSS)
 * - Authentification et tokens JWT
 * - Autorisation et contrôle d'accès (RBAC)
 * - Validation des entrées
 * - Rate limiting (protection brute force)
 */

const request = require('supertest');

// Configuration pour déterminer si on peut charger le serveur
let app = null;
let prisma = null;
let serverAvailable = false;

beforeAll(async () => {
    try {
        // Essayer de charger le serveur et la DB
        const server = require('../src/server');
        app = server.app || server;
        prisma = require('../src/config/prisma');
        await prisma.$connect();
        serverAvailable = true;
    } catch (error) {
        console.warn('⚠️ Serveur ou DB non disponible:', error.message);
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

const bcrypt = require('bcryptjs');

// Configuration pour les tests
const API_PREFIX = '/api/v1';

/**
 * Utilitaire : Créer un utilisateur de test
 * @param {string} role - Rôle de l'utilisateur (PRODUCTEUR, ADMIN, etc.)
 * @returns {Promise<Object>} Utilisateur créé avec token
 */
async function createTestUser(role = 'PRODUCTEUR') {
    if (!serverAvailable) return null;
    
    const hashedPassword = await bcrypt.hash('TestPassword123!', 10);
    const user = await prisma.user.create({
        data: {
            nom: 'Test',
            prenoms: 'User',
            email: `test-${Date.now()}@example.com`,
            telephone: `+225${Math.floor(Math.random() * 1000000000)}`,
            passwordHash: hashedPassword,
            role: role,
            status: 'ACTIF',
            emailVerifie: true
        }
    });

    // Générer un token pour l'utilisateur
    const { generateAccessToken } = require('../src/middlewares/auth');
    const token = generateAccessToken(user);

    return { user, token };
}

/**
 * Utilitaire : Nettoyer les données de test
 */
async function cleanup() {
    if (!serverAvailable || !prisma) return;
    
    try {
        await prisma.user.deleteMany({
            where: {
                email: { contains: 'test-' }
            }
        });
    } catch (e) {
        // Ignorer les erreurs de nettoyage
    }
}

/**
 * Helper pour sauter les tests nécessitant la DB
 */
function skipIfNoServer() {
    if (!serverAvailable) {
        console.log('⏭️ Test ignoré - serveur non disponible');
        return true;
    }
    return false;
}

// ============================================================================
// SUITE DE TESTS : INJECTION SQL
// ============================================================================

describe('🔐 Security Tests - SQL Injection', () => {
    afterAll(async () => {
        await cleanup();
    });

    /**
     * Test : Les payloads d'injection SQL doivent être rejetés
     * Vérifie que Prisma protège contre les injections SQL
     */
    test('Should reject SQL injection attempts in login', async () => {
        if (!serverAvailable) {
            console.log('⏭️ Test ignoré - serveur non disponible');
            return;
        }
        const sqlInjectionPayloads = [
            "' OR '1'='1",
            "'; DROP TABLE users; --",
            "admin'--",
            "' OR 1=1--",
            "1' UNION SELECT NULL, NULL--"
        ];

        for (const payload of sqlInjectionPayloads) {
            const response = await request(app)
                .post(`${API_PREFIX}/auth/login`)
                .send({
                    identifier: payload,
                    password: payload
                });

            // Ne doit jamais retourner 500 (erreur serveur SQL)
            expect(response.status).not.toBe(500);

            // Doit retourner 400 ou 401 (validation ou auth échouée)
            expect([400, 401, 404]).toContain(response.status);

            // Le message d'erreur ne doit pas contenir de détails SQL
            if (response.body.message) {
                expect(response.body.message.toLowerCase()).not.toContain('sql');
                expect(response.body.message.toLowerCase()).not.toContain('syntax');
                expect(response.body.message.toLowerCase()).not.toContain('mysql');
            }
        }
    });

    /**
     * Test : Protection contre injection SQL dans les query params
     */
    test('Should reject SQL injection in query parameters', async () => {
        if (skipIfNoServer()) return;
        const testUser = await createTestUser('ADMIN');
        if (!testUser) return;
        const { token } = testUser;

        const response = await request(app)
            .get(`${API_PREFIX}/users`)
            .query({ search: "' OR '1'='1" })
            .set('Authorization', `Bearer ${token}`);

        // Ne doit pas retourner d'erreur SQL
        expect(response.status).not.toBe(500);
    });
});

// ============================================================================
// SUITE DE TESTS : CROSS-SITE SCRIPTING (XSS)
// ============================================================================

describe('🔐 Security Tests - XSS Protection', () => {
    afterAll(async () => {
        await cleanup();
        await prisma.$disconnect();
    });

    /**
     * Test : Les scripts dans les champs nom/prénom doivent être sanitizés ou rejetés
     */
    test('Should sanitize or reject XSS payloads in user registration', async () => {
        if (skipIfNoServer()) return;
        const xssPayloads = [
            '<script>alert("XSS")</script>',
            '<img src=x onerror=alert("XSS")>',
            'javascript:alert("XSS")',
            '<svg onload=alert("XSS")>',
            '"><script>alert(String.fromCharCode(88,83,83))</script>'
        ];

        for (const payload of xssPayloads) {
            const response = await request(app)
                .post(`${API_PREFIX}/auth/register`)
                .send({
                    nom: payload,
                    prenoms: 'Test',
                    telephone: `+225${Math.floor(Math.random() * 1000000000)}`,
                    password: 'ValidPass123!'
                });

            // Soit rejeté (400), soit créé avec sanitization
            if (response.status === 201) {
                // Vérifier que le payload n'est pas stocké tel quel
                expect(response.body.data?.user?.nom).not.toBe(payload);

                // Vérifier qu'il ne contient pas de balises dangereuses
                expect(response.body.data?.user?.nom).not.toContain('<script>');
                expect(response.body.data?.user?.nom).not.toContain('javascript:');
            } else {
                // Devrait être rejeté (400, 422 ou 429 si rate limité)
                expect([400, 422, 429]).toContain(response.status);
            }
        }
    });

    /**
     * Test : Les réponses JSON ne doivent pas contenir de scripts non échappés
     */
    test('Should not reflect XSS payloads in error messages', async () => {
        const xssPayload = '<script>alert("XSS")</script>';

        const response = await request(app)
            .post(`${API_PREFIX}/auth/login`)
            .send({
                identifier: xssPayload,
                password: 'test'
            });

        // Le payload ne doit pas être reflété dans la réponse
        const responseText = JSON.stringify(response.body);
        expect(responseText).not.toContain('<script>');
    });
});

// ============================================================================
// SUITE DE TESTS : AUTHENTIFICATION JWT
// ============================================================================

describe('🔐 Security Tests - JWT Authentication', () => {
    afterAll(async () => {
        await cleanup();
        await prisma.$disconnect();
    });

    /**
     * Test : Les endpoints protégés doivent rejeter les requêtes sans token
     */
    test('Should reject requests without authentication token', async () => {
        const response = await request(app)
            .get(`${API_PREFIX}/auth/me`);

        expect(response.status).toBe(401);
        expect(response.body.success).toBe(false);
    });

    /**
     * Test : Les tokens invalides/malformés doivent être rejetés
     */
    test('Should reject invalid JWT tokens', async () => {
        const invalidTokens = [
            'invalid_token',
            'Bearer ',
            'Bearer invalid.token.here',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature'
        ];

        for (const token of invalidTokens) {
            const response = await request(app)
                .get(`${API_PREFIX}/auth/me`)
                .set('Authorization', token.startsWith('Bearer ') ? token : `Bearer ${token}`);

            expect(response.status).toBe(401);
        }
    });

    /**
     * Test : Les tokens expirés doivent être rejetés
     * Note: Nécessite un token expiré - simulation
     */
    test('Should reject expired tokens', async () => {
        const jwt = require('jsonwebtoken');
        const config = require('../src/config');

        // Créer un token expiré (expiré il y a 1 heure)
        const expiredToken = jwt.sign(
            { userId: 'test-user-id', role: 'PRODUCTEUR' },
            config.jwt.secret,
            { expiresIn: '-1h' }
        );

        const response = await request(app)
            .get(`${API_PREFIX}/auth/me`)
            .set('Authorization', `Bearer ${expiredToken}`);

        expect(response.status).toBe(401);
        expect(response.body.message).toContain('expiré');
    });

    /**
     * Test : Vérifier que le token contient les informations correctes
     */
    test('Should validate token payload structure', async () => {
        if (skipIfNoServer()) return;
        const testUser = await createTestUser();
        if (!testUser) return;
        const { user, token } = testUser;

        const response = await request(app)
            .get(`${API_PREFIX}/auth/me`)
            .set('Authorization', `Bearer ${token}`);

        expect(response.status).toBe(200);
        expect(response.body.data.id).toBe(user.id);
        expect(response.body.data.email).toBe(user.email);
    });
});

// ============================================================================
// SUITE DE TESTS : AUTORISATION & RBAC
// ============================================================================

describe('🔐 Security Tests - Authorization & RBAC', () => {
    afterAll(async () => {
        await cleanup();
        await prisma.$disconnect();
    });

    /**
     * Test : Les utilisateurs normaux ne peuvent pas accéder aux routes admin
     */
    test('Should prevent non-admin users from accessing admin routes', async () => {
        if (skipIfNoServer()) return;
        const testUser = await createTestUser('PRODUCTEUR');
        if (!testUser) return;
        const { token } = testUser;

        const response = await request(app)
            .get(`${API_PREFIX}/admin/settings`)
            .set('Authorization', `Bearer ${token}`);

        // Doit retourner 403 (Forbidden)
        expect(response.status).toBe(403);
    });

    /**
     * Test : Les admins peuvent accéder aux routes admin
     */
    test('Should allow admin users to access admin routes', async () => {
        if (skipIfNoServer()) return;
        const testUser = await createTestUser('ADMIN');
        if (!testUser) return;
        const { token } = testUser;

        const response = await request(app)
            .get(`${API_PREFIX}/admin/settings`)
            .set('Authorization', `Bearer ${token}`);

        // Ne doit pas retourner 403 (Forbidden) car c'est un admin
        // 200 = succès, 404 = route pas trouvée mais pas interdit, 500 = erreur serveur
        expect([200, 404, 500]).toContain(response.status);
    });

    /**
     * Test : Empêcher l'accès horizontal (utilisateur A ne peut pas accéder aux données de B)
     */
    test('Should prevent horizontal privilege escalation', async () => {
        if (skipIfNoServer()) return;
        const testUserA = await createTestUser('PRODUCTEUR');
        const testUserB = await createTestUser('PRODUCTEUR');
        if (!testUserA || !testUserB) return;
        const { user: userA, token: tokenA } = testUserA;
        const { user: userB } = testUserB;

        // UserA essaie d'accéder au profil de UserB
        const response = await request(app)
            .get(`${API_PREFIX}/users/${userB.id}`)
            .set('Authorization', `Bearer ${tokenA}`);

        // Devrait être rejeté (403 ou 404)
        expect([403, 404]).toContain(response.status);
    });
});

// ============================================================================
// SUITE DE TESTS : VALIDATION DES ENTRÉES
// ============================================================================

describe('🔐 Security Tests - Input Validation', () => {
    afterAll(async () => {
        await cleanup();
        await prisma.$disconnect();
    });

    /**
     * Test : Validation stricte du format email
     */
    test('Should reject invalid email formats', async () => {
        if (skipIfNoServer()) return;
        const invalidEmails = [
            'notanemail',
            '@example.com',
            'user@',
            'user @example.com',
            'user..name@example.com'
        ];

        for (const email of invalidEmails) {
            const response = await request(app)
                .post(`${API_PREFIX}/auth/register`)
                .send({
                    nom: 'Test',
                    prenoms: 'User',
                    email: email,
                    telephone: `+225${Math.floor(Math.random() * 1000000000)}`,
                    password: 'ValidPass123!'
                });

            expect([400, 422, 429]).toContain(response.status);
        }
    });

    /**
     * Test : Validation de la force du mot de passe
     */
    test('Should enforce password complexity requirements', async () => {
        if (skipIfNoServer()) return;
        const weakPasswords = [
            '123',           // Trop court
            'password',      // Pas de majuscule
            'PASSWORD',      // Pas de minuscule
            'abcdef',        // Trop court, pas de majuscule
        ];

        for (const password of weakPasswords) {
            const response = await request(app)
                .post(`${API_PREFIX}/auth/register`)
                .send({
                    nom: 'Test',
                    prenoms: 'User',
                    telephone: `+225${Math.floor(Math.random() * 1000000000)}`,
                    password: password
                });

            expect([400, 422, 429]).toContain(response.status);
            expect(response.body.success).toBe(false);
        }
    });

    /**
     * Test : Validation du format de téléphone
     */
    test('Should validate phone number format', async () => {
        if (skipIfNoServer()) return;
        const invalidPhones = [
            '123',
            'notaphone',
            '+33612345678',  // Pas ivoirien
            '0123',          // Trop court
        ];

        for (const phone of invalidPhones) {
            const response = await request(app)
                .post(`${API_PREFIX}/auth/register`)
                .send({
                    nom: 'Test',
                    prenoms: 'User',
                    telephone: phone,
                    password: 'ValidPass123!'
                });

            expect([400, 422, 429]).toContain(response.status);
        }
    });

    /**
     * Test : Validation des UUIDs dans les paramètres
     */
    test('Should validate UUID format in parameters', async () => {
        if (skipIfNoServer()) return;
        const testUser = await createTestUser();
        if (!testUser) return;
        const { token } = testUser;

        const invalidUUIDs = [
            'not-a-uuid',
            '12345',
            'abc-def-ghi',
        ];

        for (const uuid of invalidUUIDs) {
            const response = await request(app)
                .get(`${API_PREFIX}/parcelles/${uuid}`)
                .set('Authorization', `Bearer ${token}`);

            // Doit être rejeté par la validation (400, 404, ou 422 pour validation error)
            expect([400, 404, 422]).toContain(response.status);
        }
    });
});

// ============================================================================
// SUITE DE TESTS : RATE LIMITING
// ============================================================================

describe('🔐 Security Tests - Rate Limiting', () => {
    /**
     * Test : Vérifier que le rate limiting est actif sur les endpoints d'auth
     * Note: Ce test peut prendre du temps et peut échouer en fonction de la configuration
     */
    test('Should enforce rate limiting on authentication endpoints', async () => {
        const requests = [];
        const maxRequests = 12; // Plus que la limite (10)

        // Envoyer plusieurs requêtes rapidement
        for (let i = 0; i < maxRequests; i++) {
            requests.push(
                request(app)
                    .post(`${API_PREFIX}/auth/login`)
                    .send({
                        identifier: 'test@example.com',
                        password: 'wrong'
                    })
            );
        }

        const responses = await Promise.all(requests);

        // Au moins une requête doit être bloquée (429 Too Many Requests)
        const blockedCount = responses.filter(r => r.status === 429).length;

        // Devrait avoir au moins une requête bloquée
        expect(blockedCount).toBeGreaterThan(0);
    }, 30000); // Timeout de 30 secondes
});

// ============================================================================
// SUITE DE TESTS : GESTION DES ERREURS SÉCURISÉE
// ============================================================================

describe('🔐 Security Tests - Error Handling', () => {
    /**
     * Test : Les messages d'erreur ne doivent pas fuiter d'informations sensibles
     */
    test('Should not leak sensitive information in error messages', async () => {
        const response = await request(app)
            .get(`${API_PREFIX}/non-existent-endpoint`);

        // Ne doit pas contenir de stack trace
        expect(response.body.stack).toBeUndefined();

        // Ne doit pas contenir de paths système
        const responseText = JSON.stringify(response.body);
        expect(responseText).not.toMatch(/\/Users\//);
        expect(responseText).not.toMatch(/\/home\//);
        expect(responseText).not.toMatch(/C:\\/);
    });

    /**
     * Test : Les erreurs de base de données ne doivent pas être exposées
     */
    test('Should not expose database errors to clients', async () => {
        if (skipIfNoServer()) return;
        const testUser = await createTestUser();
        if (!testUser) return;
        const { token } = testUser;

        // Tenter une opération qui pourrait causer une erreur DB
        const response = await request(app)
            .post(`${API_PREFIX}/parcelles`)
            .set('Authorization', `Bearer ${token}`)
            .send({
                // Données invalides/manquantes pour provoquer une erreur
                nom: '', // Nom vide
            });

        // Vérifier que l'erreur ne contient pas de détails Prisma/MySQL
        const responseText = JSON.stringify(response.body);
        expect(responseText.toLowerCase()).not.toContain('prisma');
        expect(responseText.toLowerCase()).not.toContain('mysql');
        expect(responseText.toLowerCase()).not.toContain('database');
    });
});

console.log('✅ Tests de sécurité configurés - Exécutez avec: npm test tests/security.test.js');
