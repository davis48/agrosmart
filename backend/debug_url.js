require('dotenv').config();
const { URL } = require('url');

const dbUrl = process.env.DATABASE_URL;
console.log('Original URL:', dbUrl);

const url = new URL(dbUrl);
console.log('Parsed hostname:', url.hostname);
console.log('Parsed port:', url.port);
console.log('Parsed username:', url.username);
console.log('Parsed password:', url.password ? '****' : 'EMPTY');
console.log('Parsed pathname:', url.pathname);
