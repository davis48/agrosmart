require('dotenv').config();
const mysql = require('mysql2/promise');

async function test() {
    try {
        console.log('Testing mysql2 connection...');
        const connection = await mysql.createConnection(process.env.DATABASE_URL);
        console.log('Connected!');
        const [rows] = await connection.execute('SELECT 1 as result');
        console.log('Query result:', rows);
        await connection.end();
    } catch (e) {
        console.error('Connection Failed:', e);
    }
}

test();
