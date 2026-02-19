const axios = require('axios');

async function testRegister() {
    const email = `test_parcelle_${Date.now()}@example.com`;
    // Valid phone format: +225 followed by 10 digits starting with 01, 05, 07 etc.
    // Using 01 + 8 random digits
    const telephone = `+22501${Date.now().toString().slice(-8)}`;

    const payload = {
        nom: "Test",
        prenoms: "User",
        telephone: telephone,
        email: email,
        password: "Password123!", // Uppercase + Number + Special char
        role: "PRODUCTEUR",
        // Simulation of productions list from mobile
        productions: [
            { type: "Cacao", surface: 5.5 },
            { type: "Hévéa", surface: 3.0 }
        ]
    };

    console.log("Sending registration payload:", JSON.stringify(payload, null, 2));

    try {
        // Assuming backend is running on localhost:3600
        const response = await axios.post('http://localhost:3600/api/v1/auth/register', payload);
        console.log("Registration Response:", response.status, response.data);

        // Now login to get token and check parcelles
        const loginResponse = await axios.post('http://localhost:3600/api/v1/auth/login', {
            identifier: email,
            password: "Password123!"
        });

        const token = loginResponse.data.data.token;
        console.log("Login successful. Token obtained.");

        // Check parcelles
        const parcellesResponse = await axios.get('http://localhost:3600/api/v1/parcelles', {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log("Parcelles found:", parcellesResponse.data.data.length);
        console.log("Parcelles data:", JSON.stringify(parcellesResponse.data.data, null, 2));

    } catch (error) {
        if (error.response) {
            console.error("Error Response:", error.response.status, error.response.data);
        } else {
            console.error("Error:", error.message);
        }
    }
}

testRegister();
