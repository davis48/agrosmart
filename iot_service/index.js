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
            description: 'IoT Gateway Service for AgroSmart'
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
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || undefined,
    // Required by BullMQ v5 to avoid unhandled promise rejections on timeout
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
};

const sensorQueue = new Queue('sensor-data', {
    connection,
    // Don't crash the process on Redis connect failure
    defaultJobOptions: { removeOnComplete: 100, removeOnFail: 50 },
});

// Track Redis connection errors
sensorQueue.on('error', (err) => {
    // Ignore ECONNREFUSED during retry cycle — it is expected when Redis is down
    if (err.code !== 'ECONNREFUSED') {
        console.error('[Redis] Queue error:', err.message);
    }
    redisConnected = false;
});

// Check Redis connection on startup using BullMQ v5 API
(async () => {
    try {
        await sensorQueue.waitUntilReady();
        redisConnected = true;
        console.log('[Redis] Connected to Redis successfully');
    } catch (err) {
        console.error('[Redis] Connection failed (service will retry automatically):', err.message);
        console.warn('[Redis] IoT service is running without Redis — sensor data will NOT be queued.');
        redisConnected = false;
    }
})();

// Configuration MQTT
const MQTT_BROKER = process.env.MQTT_BROKER_URL || process.env.MQTT_BROKER || 'mqtt://test.mosquitto.org';
const MQTT_TOPIC = process.env.MQTT_TOPIC || 'agrosmart/+/up';

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
        // Extract device ID from topic (assuming format agrosmart/{device_id}/up)
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
    // Envoie { device_code, values, timestamp } dans la queue.
    // Le worker backend (sensorWorker.js) est responsable du lookup UUID par device_code.
    if (!redisConnected) {
        console.warn(`[Queue] Redis indisponible — données du device "${deviceCode}" ignorées.`);
        return;
    }

    try {
        await sensorQueue.add('process-mqtt', {
            device_code: deviceCode,
            values: data,
            timestamp: new Date(),
        });
        console.log(`[Queue] Enqueued data for device: ${deviceCode}`);
    } catch (err) {
        console.error(`[Queue] Failed to enqueue data for device "${deviceCode}":`, err.message);
        redisConnected = false;
    }
}
