const bcrypt = require('bcryptjs');

const password = 'password';
const hash = bcrypt.hashSync(password, 10);

console.log('Password:', password);
console.log('Hash:', hash);
console.log('\nSQL Command:');
console.log(`UPDATE users SET password_hash = '${hash}' WHERE telephone = '0505050505';`);
