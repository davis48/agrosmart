/**
 * Service de file d'attente pour l'ingestion IoT
 * REDIS DISABLED - BullMQ is not used
 * The application falls back to synchronous processing
 */
// const { Queue } = require('bullmq'); // REDIS DISABLED
const config = require('../config');
const logger = require('../utils/logger');

// REDIS CONFIGURATION - DISABLED
// const connection = {
//     host: config.redis.host,
//     port: config.redis.port,
//     password: config.redis.password
// };

let sensorQueue = null;

const getSensorQueue = () => {
    // Redis is disabled, return null (triggers sync fallback)
    return null;
    
    // OLD CODE (DISABLED):
    // if (!config.redis.enabled) {
    //     return null;
    // }
    // if (!sensorQueue) {
    //     sensorQueue = new Queue('sensor-data', { ... });
    // }
    // return sensorQueue;
};

/**
 * Ajouter une mesure à la file d'attente
 * Falls back to synchronous processing since Redis is disabled
 * @param {Object} data Données de la mesure (capteur_id, valeur, unite, timestamp)
 */
exports.addJob = async (data) => {
    try {
        // Redis is disabled, use synchronous processing
        if (!config.redis.enabled) {
            logger.debug('[Queue] Processing measure synchronously (Redis disabled)', { data });
            const { processMeasure } = require('../workers/sensorWorker');
            return processMeasure({ id: `sync-${Date.now()}`, data });
        }

        // This code won't be reached since Redis is disabled
        // const queue = getSensorQueue();
        // return await queue.add('process-measure', data);
    } catch (error) {
        logger.error('Échec traitement mesure', { error: error.message });
        throw error;
    }
};

/**
 * Obtenir le client de la file (pour monitoring éventuel)
 */
exports.getQueue = () => getSensorQueue();
