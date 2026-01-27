/**
 * Tests d'intégration WebSocket (Socket.io)
 * AgriSmart CI - Backend
 */

const { createServer } = require('http');
const { Server } = require('socket.io');
const Client = require('socket.io-client');
const jwt = require('jsonwebtoken');

// Mock config
jest.mock('../../src/config', () => ({
    jwt: { secret: 'test-secret-key' },
    isProd: false,
    cors: { origin: '*' }
}));

describe('WebSocket Integration Tests', () => {
    let io, serverSocket, clientSocket, httpServer;
    const testUser = { id: 'user-123', role: 'PRODUCTEUR' };
    let validToken;

    beforeAll((done) => {
        // Créer un token valide pour les tests
        validToken = jwt.sign(testUser, 'test-secret-key', { expiresIn: '1h' });
        
        // Créer le serveur HTTP et Socket.io
        httpServer = createServer();
        io = new Server(httpServer, {
            cors: { origin: '*' }
        });

        // Middleware d'authentification (simplifié pour les tests)
        io.use((socket, next) => {
            const token = socket.handshake.query.token;
            if (token) {
                try {
                    const decoded = jwt.verify(token, 'test-secret-key');
                    socket.user = decoded;
                    next();
                } catch (err) {
                    next(new Error('Authentication error'));
                }
            } else {
                next(new Error('Authentication error'));
            }
        });

        httpServer.listen(() => {
            const port = httpServer.address().port;
            
            // Configurer les handlers Socket.io
            io.on('connection', (socket) => {
                serverSocket = socket;
                
                socket.join(`user_${socket.user.id}`);
                
                socket.on('join_conversation', (conversationId) => {
                    socket.join(`conversation_${conversationId}`);
                    socket.emit('joined', { conversationId });
                });
                
                socket.on('typing', (data) => {
                    socket.to(`conversation_${data.conversationId}`).emit('user_typing', {
                        userId: socket.user.id,
                        conversationId: data.conversationId
                    });
                });
                
                socket.on('send_message', (data) => {
                    io.to(`conversation_${data.conversationId}`).emit('new_message', {
                        ...data,
                        senderId: socket.user.id,
                        timestamp: new Date()
                    });
                });

                socket.on('subscribe_parcelle', (parcelleId) => {
                    socket.join(`parcelle:${parcelleId}`);
                    socket.emit('subscribed', { parcelleId });
                });
            });

            // Créer le client
            clientSocket = Client(`http://localhost:${port}`, {
                query: { token: validToken }
            });
            
            clientSocket.on('connect', done);
        });
    });

    afterAll(() => {
        io.close();
        clientSocket.close();
        httpServer.close();
    });

    describe('Authentication', () => {
        test('should connect with valid token', (done) => {
            expect(clientSocket.connected).toBe(true);
            done();
        });

        test('should reject connection with invalid token', (done) => {
            const port = httpServer.address().port;
            const badClient = Client(`http://localhost:${port}`, {
                query: { token: 'invalid-token' }
            });

            badClient.on('connect_error', (err) => {
                expect(err.message).toContain('error');
                badClient.close();
                done();
            });
        });

        test('should reject connection without token', (done) => {
            const port = httpServer.address().port;
            const noTokenClient = Client(`http://localhost:${port}`);

            noTokenClient.on('connect_error', (err) => {
                expect(err.message).toContain('error');
                noTokenClient.close();
                done();
            });
        });
    });

    describe('Conversations', () => {
        test('should join a conversation room', (done) => {
            const conversationId = 'conv-456';
            
            clientSocket.emit('join_conversation', conversationId);
            
            clientSocket.once('joined', (data) => {
                expect(data.conversationId).toBe(conversationId);
                done();
            });
        });

        test('should receive messages in conversation', (done) => {
            const conversationId = 'conv-789';
            const messageContent = 'Test message';
            
            // First join, then wait for joined event before sending message
            clientSocket.once('joined', (data) => {
                expect(data.conversationId).toBe(conversationId);
                
                clientSocket.once('new_message', (msgData) => {
                    expect(msgData.content).toBe(messageContent);
                    expect(msgData.senderId).toBe(testUser.id);
                    done();
                });
                
                // Send message after join is confirmed
                setTimeout(() => {
                    clientSocket.emit('send_message', {
                        conversationId,
                        content: messageContent
                    });
                }, 50);
            });
            
            clientSocket.emit('join_conversation', conversationId);
        });
    });

    describe('Parcelles Subscription', () => {
        test('should subscribe to parcelle updates', (done) => {
            const parcelleId = 'parcelle-123';
            
            clientSocket.emit('subscribe_parcelle', parcelleId);
            
            clientSocket.once('subscribed', (data) => {
                expect(data.parcelleId).toBe(parcelleId);
                done();
            });
        });
    });

    describe('Real-time Alerts', () => {
        test('should receive alerts targeted to user', (done) => {
            const alertData = {
                id: 'alert-1',
                type: 'IRRIGATION',
                niveau: 'IMPORTANT',
                message: 'Irrigation nécessaire'
            };

            clientSocket.on('alert:new', (data) => {
                expect(data.id).toBe(alertData.id);
                expect(data.type).toBe(alertData.type);
                done();
            });

            // Simuler l'envoi d'une alerte depuis le serveur
            setTimeout(() => {
                io.to(`user_${testUser.id}`).emit('alert:new', alertData);
            }, 100);
        });
    });

    describe('Measurements Updates', () => {
        test('should receive sensor measurements for subscribed parcelle', (done) => {
            const parcelleId = 'parcelle-measure-test';
            const measurement = {
                capteurId: 'sensor-1',
                type: 'HUMIDITE_SOL',
                valeur: 45.5,
                timestamp: new Date()
            };

            // Wait for subscription confirmation before expecting measurement
            clientSocket.once('subscribed', (subData) => {
                expect(subData.parcelleId).toBe(parcelleId);
                
                clientSocket.once('measurement:new', (data) => {
                    expect(data.capteurId).toBe(measurement.capteurId);
                    expect(data.valeur).toBe(measurement.valeur);
                    done();
                });

                // Emit measurement after subscription is confirmed
                setTimeout(() => {
                    io.to(`parcelle:${parcelleId}`).emit('measurement:new', measurement);
                }, 100);
            });

            clientSocket.emit('subscribe_parcelle', parcelleId);
        });
    });
});
