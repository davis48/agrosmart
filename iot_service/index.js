require('dotenv').config();
const mqtt = require('mqtt');
const { Queue } = require('bullmq');
const http = require('http');

// ============================
// Health Check HTTP Server
// ============================
const PORT = process.env.PORT || 4000;
let mqttConnected = false;
let redisConnected = false;

const healthServer = http.createServer((req, res) => {
    if (req.url === '/health' && req.method === 'GET') {
        const healthy = mqttConnected && redisConnected;
        res.writeHead(healthy ? 200 : 503, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: healthy ? 'healthy' : 'unhealthy',
            mqtt: mqttConnected ? 'connected' : 'disconnected',
            redis: redisConnected ? 'connected' : 'disconnected',
            timestamp: new Date().toISOString()
        }));
    } else if (req.url === '/' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            service: 'agrismart-iot',
            version: '1.0.0',
            description: 'IoT Gateway Service for AgriSmart'
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not Found' }));
    }
});

healthServer.listen(PORT, () => {
    console.log(`[Health] HTTP server listening on port ${PORT}`);
});

// ============================
// Configuration Redis pour BullMQ
// ============================
const connection = {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD
};

const sensorQueue = new Queue('sensor-data', { connection });

// Track Redis connection
sensorQueue.on('error', (err) => {
    console.error('[Redis] Queue error:', err.message);
    redisConnected = false;
});

// Check Redis connection on startup
(async () => {
    try {
        await sensorQueue.client;
        redisConnected = true;
        console.log('[Redis] Connected to Redis');
    } catch (err) {
        console.error('[Redis] Connection failed:', err.message);
        redisConnected = false;
    }
})();

// Configuration MQTT
const MQTT_BROKER = process.env.MQTT_BROKER_URL || process.env.MQTT_BROKER || 'mqtt://test.mosquitto.org';
const MQTT_TOPIC = process.env.MQTT_TOPIC || 'agrismart/+/up';

// MQTT Authentication
const mqttOptions = {
    username: process.env.MQTT_USERNAME,
    password: process.env.MQTT_PASSWORD,
    reconnectPeriod: 5000, // Reconnect every 5 seconds
    connectTimeout: 30000,
};

console.log(`[MQTT] Connecting to Broker: ${MQTT_BROKER}`);
const client = mqtt.connect(MQTT_BROKER, mqttOptions);

client.on('connect', () => {
    mqttConnected = true;
    console.log('[MQTT] Connected to Broker');
    client.subscribe(MQTT_TOPIC, (err) => {
        if (!err) {
            console.log(`[MQTT] Subscribed to topic: ${MQTT_TOPIC}`);
        } else {
            console.error('[MQTT] Subscription error:', err);
        }
    });
});

client.on('close', () => {
    mqttConnected = false;
    console.log('[MQTT] Connection closed');
});

client.on('error', (err) => {
    mqttConnected = false;
    console.error('[MQTT] Error:', err.message);
});

client.on('message', async (topic, message) => {
    try {
        const payload = message.toString();
        // Extract device ID from topic (assuming format agrismart/{device_id}/up)
        const parts = topic.split('/');
        const deviceId = parts[1]; // e.g. "sensor_001"

        // Decode Payload
        const data = decodePayload(payload);

        if (data) {
            // Push to Queue for async processing by Backend Worker
            await enqueueMeasurement(deviceId, data);
        }
    } catch (error) {
        console.error('Error processing message:', error);
    }
});

function decodePayload(payload) {
    try {
        return JSON.parse(payload);
    } catch (e) {
        console.log('Payload is not JSON, skipping');
        return null;
    }
}

async function enqueueMeasurement(deviceCode, data) {
    // data example: { temperature: 25.5, humidity: 60 }

    // We need to look up the sensor ID from the code in the backend worker.
    // However, the current worker expects `capteur_id` (UUID).
    // Problem: IoT Service only has deviceCode (string).
    // Solution 1: Worker does lookup via code.
    // Solution 2: IoT Service does lookup.

    // To keep IoT service decoupled from DB, we should send { device_code, values } to Queue
    // And let the Worker resolve UUID.
    // BUT my current worker implementation expects 'capteur_id' (UUID).

    // I will update the worker later to handle lookup if 'capteur_id' is missing but 'device_code' is present?
    // OR for this MVP, I assume IoT service has access to DB map?
    // Let's stick to the previous implementation where IoT Service had DB Access.
    // It's faster to do lookup here (Read-only) and push UUID to queue.
    // Or even better: Worker should handle Lookup to centralize logic.

    // Let's modify Worker to accept `device_code` too.
    // For now, I will modify `iot_service` to just push raw data.
    // But wait, my worker insert query requires `capteur_id`.

    // Compromise: IoT Service looks up UUID (it already has pg pool setup in previous version, I removed it in this new file content).
    // I should re-add PG pool for lookup ONLY.

    // Actually, to make it robust, `iot_service` shouldn't touch the main DB.
    // The backend worker should do the lookup.

    // So I will push: { device_code: deviceCode, values: data, timestamp: new Date() }
    // And I will need to update `sensorWorker.js` to handle this.

    await sensorQueue.add('process-mqtt', {
        device_code: deviceCode,
        values: data,
        timestamp: new Date()
    });

    console.log(`[Queue] Enqueued data for device: ${deviceCode}`);
}
