/**
 * Service de file d'attente pour l'ingestion IoT
 * Utilise BullMQ pour gérer les mesures de manière asynchrone
 */
const { Queue } = require('bullmq');
const config = require('../config');
const logger = require('../utils/logger');

// Configuration Redis pour BullMQ (centralisée via config)
const connection = {
    host: config.redis.host,
    port: config.redis.port,
    password: config.redis.password
};

// Création de la file d'attente
const sensorQueue = new Queue('sensor-data', {
    connection,
    defaultJobOptions: {
        attempts: 3,
        backoff: {
            type: 'exponential',
            delay: 1000,
        },
        removeOnComplete: true,
        removeOnFail: 1000 // Garder les 1000 derniers échecs pour debug
    }
});

sensorQueue.on('error', (err) => {
    logger.error('Erreur file d\'attente sensor-data', { error: err.message });
});

/**
 * Ajouter une mesure à la file d'attente
 * @param {Object} data Données de la mesure (capteur_id, valeur, unite, timestamp)
 */
exports.addJob = async (data) => {
    try {
        return await sensorQueue.add('process-measure', data);
    } catch (error) {
        logger.error('Échec ajout job file d\'attente', { error: error.message });
        throw error;
    }
};

/**
 * Obtenir le client de la file (pour monitoring éventuel)
 */
exports.getQueue = () => sensorQueue;
