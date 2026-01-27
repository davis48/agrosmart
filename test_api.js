const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/v1';
const TEST_USER = {
    telephone: '0505050505',
    password: 'password' // You'll need to set this in the DB or use existing password
};

async function testAPIs() {
    try {
        console.log('🔍 Testing AgriSmart CI APIs...\n');

        // 1. Test Login
        console.log('1️⃣ Testing Login...');
        const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
            telephone: TEST_USER.telephone,
            password: TEST_USER.password
        });

        const token = loginResponse.data.data.accessToken;
        console.log('✅ Login successful! Token:', token.substring(0, 20) + '...\n');

        const headers = { Authorization: `Bearer ${token}` };

        // 2. Test Alerts
        console.log('2️⃣ Testing Alerts...');
        const alertsResponse = await axios.get(`${BASE_URL}/alertes`, { headers });
        console.log(`✅ Alerts: ${alertsResponse.data.data.length} found`);
        console.log(JSON.stringify(alertsResponse.data.data, null, 2) + '\n');

        // 3. Test Capteurs  
        console.log('3️⃣ Testing Capteurs...');
        const capteursResponse = await axios.get(`${BASE_URL}/capteurs`, { headers });
        console.log(`✅ Capteurs: ${capteursResponse.data.data.length} found`);
        console.log(JSON.stringify(capteursResponse.data.data, null, 2) + '\n');

        // 4. Test Forum
        console.log('4️⃣ Testing Forum...');
        const forumResponse = await axios.get(`${BASE_URL}/communaute/posts`, { headers });
        console.log(`✅ Forum Posts: ${forumResponse.data.data.length} found`);
        console.log(JSON.stringify(forumResponse.data.data, null, 2) + '\n');

        // 5. Test Marketplace
        console.log('5️⃣ Testing Marketplace...');
        const marketResponse = await axios.get(`${BASE_URL}/marketplace/produits`, { headers });
        console.log(`✅ Marketplace Products: ${marketResponse.data.data.length} found`);
        console.log(JSON.stringify(marketResponse.data.data, null, 2) + '\n');

    } catch (error) {
        console.error('❌ Error:', error.response?.data || error.message);
    }
}

testAPIs();
