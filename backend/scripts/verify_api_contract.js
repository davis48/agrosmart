const axios = require('axios');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
// Read port from env or default to 3000
const API_PORT = process.env.PORT || 3000;
const API_URL = `http://localhost:${API_PORT}/api/v1`; // Note: check prefix in server.js
// server.js has `app.use('/api/v1', routes);` AND `app.use('/api/parcelles', parcelles);`
// Wait. server.js has mixed mounting!
// Line 166: app.use('/api/v1', routes);
// Line 169: app.use('/api/parcelles', parcelles);
// This means /api/parcelles is accessible at http://localhost:3000/api/parcelles (v1 prefix NOT required for this specific mount?)
// BUT /api/v1/parcelles IS ALSO likely mounted inside `routes/index.js` which mounts `parcellesRoutes` at `/parcelles`.
// So http://localhost:3000/api/v1/parcelles is the standard one?
// Let's check `routes/index.js`: `router.use('/parcelles', parcellesRoutes);`.
// So yes, `api/v1/parcelles` exists.
// The `app.use('/api/parcelles', parcelles)` might be legacy or duplicate.
// I will use `http://localhost:${API_PORT}/api/v1` as base.

let TOKEN = '';

async function login() {
    console.log(`Attempting login on ${API_URL}...`);
    try {
        const response = await axios.post(`${API_URL}/auth/login`, {
            identifier: '+2250100000000',
            password: 'StrongPassword123!'
        });

        TOKEN = response.data.data.token;
        console.log('✅ Login successful');
        return true;
    } catch (error) {
        if (error.code === 'ECONNREFUSED') {
            console.error(`❌ Connection Refused on port ${API_PORT}. Is server running?`);
            return false;
        }

        if (error.response && (error.response.status === 401 || error.response.status === 404)) {
            console.log('⚠️ Login failed (401/404), attempting to register test user...');
            try {
                const regResponse = await axios.post(`${API_URL}/auth/register`, {
                    nom: 'Test',
                    prenoms: 'API Check',
                    telephone: '+2250100000000',
                    password: 'StrongPassword123!',
                    email: 'api_check@test.com'
                });
                TOKEN = regResponse.data.data.token;
                console.log('✅ Registration successful & Logged in');
                return true;
            } catch (regError) {
                console.error('❌ Failed to register/login:', regError.response ? regError.response.data : regError.message);
                return false;
            }
        }
        console.error('❌ Login error:', error.message);
        if (error.response) console.error('Status:', error.response.status, 'Data:', error.response.data);
        return false;
    }
}

async function verifyParcelles() {
    console.log('Checking Parcelles...');
    try {
        // Updated mounting point check
        const response = await axios.get(`${API_URL}/parcelles`, {
            headers: { Authorization: `Bearer ${TOKEN}` }
        });

        let data = response.data.data;
        if (!Array.isArray(data)) throw new Error('Data is not an array');

        if (data.length === 0) {
            console.log('⚠️ No parcelles found. Creating a test parcelle...');
            try {
                const createResponse = await axios.post(`${API_URL}/parcelles`, {
                    nom: 'Parcelle Test Contract',
                    superficie: 2.5,
                    type_sol: 'argileux',
                    culture: 'mais',
                    status: 'ACTIVE'
                }, { headers: { Authorization: `Bearer ${TOKEN}` } });

                // Fetch again to check list response format
                const refreshResponse = await axios.get(`${API_URL}/parcelles`, {
                    headers: { Authorization: `Bearer ${TOKEN}` }
                });
                data = refreshResponse.data.data;
                console.log('✅ Test parcelle created.');
            } catch (createError) {
                console.error('❌ Failed to create test parcelle:', createError.response ? createError.response.data : createError.message);
                return;
            }
        }

        const item = data[0];
        const missingKeys = [];
        const requiredKeys = ['id', 'nom', 'superficie', 'type_sol', 'status', 'created_at', 'updated_at'];

        requiredKeys.forEach(key => {
            if (item[key] === undefined) missingKeys.push(key);
        });

        if (missingKeys.length > 0) {
            console.error('❌ Parcelles Contract Failed. Missing keys:', missingKeys);
            console.log('Sample item keys:', Object.keys(item));
        } else {
            console.log('✅ Parcelles Contract Verified');
        }
    } catch (error) {
        console.error('❌ Parcelles Check Error:', error.message);
    }
}

async function verifyMarketplace() {
    console.log('Checking Marketplace...');
    try {
        const response = await axios.get(`${API_URL}/marketplace/produits`, {
            headers: { Authorization: `Bearer ${TOKEN}` }
        });
        if (response.status === 200) console.log('✅ Marketplace Verified');
    } catch (error) {
        console.error('❌ Marketplace Check Error:', error.message);
    }
}

async function verifyWeather() {
    console.log('Checking Weather...');
    try {
        const response = await axios.get(`${API_URL}/weather/current?lat=5.35&lon=-4.00`);
        if (response.status === 200) console.log('✅ Weather Verified');
    } catch (error) {
        console.error('❌ Weather Check Error:', error.message);
    }
}

async function verifyFormations() {
    console.log('Checking Formations...');
    try {
        const response = await axios.get(`${API_URL}/formations`, {
            headers: { Authorization: `Bearer ${TOKEN}` }
        });
        if (response.status === 200) console.log('✅ Formations Verified');
    } catch (error) {
        console.error('❌ Formations Check Error:', error.message);
    }
}

async function run() {
    console.log('🚀 Starting API Contract Verification...');
    if (await login()) {
        await verifyParcelles();
        await verifyMarketplace();
        await verifyWeather();
        await verifyFormations();
    }
    prisma.$disconnect();
}

run();
