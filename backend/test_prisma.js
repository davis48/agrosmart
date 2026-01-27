require('dotenv').config();
const prisma = require('./src/config/prisma');
const bcrypt = require('bcryptjs');

async function test() {
    try {
        console.log('Connecting to Prisma...');
        await prisma.$connect();
        console.log('Connected!');

        const email = `test_manual_${Date.now()}@example.com`;
        const passwordHash = await bcrypt.hash('password123', 10);

        console.log('Creating test user...');
        const user = await prisma.user.create({
            data: {
                nom: 'Test',
                prenoms: 'Manual',
                email,
                passwordHash,
                role: 'PRODUCTEUR',
                status: 'ACTIF',
                telephone: `01${Date.now().toString().slice(-8)}`
            }
        });
        console.log('User created:', user.id);

        const jwt = require('jsonwebtoken');
        const config = require('./src/config');
        const token = jwt.sign({ userId: user.id, role: user.role }, config.jwt.secret, { expiresIn: '1h' });
        console.log('TOKEN:', token);
        await prisma.user.delete({ where: { id: user.id } });
        console.log('Deleted!');

    } catch (e) {
        console.error('Test Failed:', e);
    } finally {
        await prisma.$disconnect();
    }
}

test();
