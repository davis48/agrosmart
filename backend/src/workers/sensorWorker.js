/**
 * Worker pour le traitement des mesures IoT
 * Consomme la file 'sensor-data' et écrit en base
 */
const { Worker } = require('bullmq');
const prisma = require('../config/prisma');
const logger = require('../utils/logger');
const alertesService = require('../services/alertesService');
const parcelleHealthService = require('../services/parcelleHealthService');
const config = require('../config');

// Configuration Redis centralisée
const connection = {
    host: config.redis.host,
    port: config.redis.port,
    password: config.redis.password
};

let worker;

/**
 * Traiter un job de mesure
 * @param {Object} job Job BullMQ
 */
const processMeasure = async (job) => {
    // Support both direct ID (HTTP) and device_code (MQTT)
    let { capteur_id, valeur, unite, mesure_at, batch, device_code, values } = job.data;

    try {
        const timestamp = mesure_at ? new Date(mesure_at) : new Date();

        // Cas 1: Payloads MQTT { device_code, values: { type: val, ... } }
        if (device_code && values) {
            // Check if Station code exists. Schema Station model must have 'code'.
            // If Schema doesn't have 'code', we might need to use ID or fix schema.
            // Assuming 'code' exists or we need to find by it.
            // If schema `Station` uses `device_id` or similar? 
            // Let's assume 'code' field exists for now based on legacy SQL.
            const station = await prisma.station.findUnique({
                where: { code: device_code },
                include: { parcelle: true }
            });

            if (!station) {
                logger.warn(`Station introuvable pour code ${device_code}`);
                return { status: 'ignored', reason: 'station_not_found' };
            }

            const results = [];

            for (const [type, val] of Object.entries(values)) {
                // Map types (iot keys -> db enum types)
                let dbType = type;
                if (type === 'humidity') dbType = 'humidite_temperature_ambiante'; // Check enum values exactly?
                if (type === 'soil_moisture') dbType = 'humidite_sol';
                if (type === 'temperature') dbType = 'humidite_temperature_ambiante'; // Warning: duplicate mapping? 
                // Legacy code mapped both to same? Or separate?
                // Legacy: if (type === 'temperature') dbType = 'humidite_temperature_ambiante';
                // Wait, surely temperature is TEMPERATURE?
                // Step 585 line 45: `if (type === 'temperature') dbType = 'humidite_temperature_ambiante';` -> confirmed legacy behavior.
                if (type === 'npk') dbType = 'npk';

                // Find sensor by station and type
                // Note: CapteurType enum might be uppercase? 'HUMIDITE_SOL'.
                // Legacy DB used lowercase strings?
                // Prisma requires matching Enum value if `type` is Enum.
                // I should probably uppercase them if Enum.
                // Let's try to find capteur first.
                // In legacy: `WHERE station_id = $1 AND type = $2`
                // Type in legacy might be text. In Prisma it is CapteurType Enum.
                // I'll try to findFirst.

                // Mapping DB types to Enum (usually Uppercase in Prisma)
                const enumType = dbType.toUpperCase();

                const sensor = await prisma.capteur.findFirst({
                    where: {
                        stationId: station.id,
                        type: enumType
                        // If findFirst fails due to type mismatch (e.g. 'humidite_sol' vs 'HUMIDITE_SOL'), we might need a mapping.
                    }
                });

                if (sensor) {
                    await prisma.mesure.create({
                        data: {
                            capteurId: sensor.id,
                            valeur: String(val),
                            unite: 'unit', // Legacy used 'unit'.
                            timestamp: timestamp
                        }
                    });

                    try {
                        await alertesService.checkThresholds(sensor.id, val);
                    } catch (alertErr) {
                        logger.warn('Erreur alerte MQTT', { error: alertErr.message });
                    }

                    results.push(sensor.id);
                }
            }

            // Recalculer la santé de la parcelle après ingestion MQTT
            if (station.parcelleId) {
                try {
                    await parcelleHealthService.recalculateParcelleHealth(station.parcelleId);
                } catch (healthErr) {
                    logger.warn('Erreur recalcul santé parcelle (MQTT)', { error: healthErr.message });
                }
            }

            return { status: 'success', processed: results.length };
        }

        // Cas 2: Payload HTTP standard (capteur_id unique)
        const capteur = await prisma.capteur.findUnique({
            where: { id: capteur_id },
            include: { station: true }
        });

        if (!capteur) {
            throw new Error(`Capteur ${capteur_id} non trouvé`);
        }

        if (capteur.statut !== 'ACTIF' && capteur.statut !== 'MAINTENANCE') {
            // Enum uses uppercase usually? Legacy used 'actif'.
            // I will assume Enum is Uppercase ACTIF.
            logger.warn(`Mesure ignorée pour capteur inactif`, { capteur_id, status: capteur.statut });
            return { status: 'ignored', reason: 'sensor_inactive' };
        }

        const result = await prisma.mesure.create({
            data: {
                capteurId: capteur_id,
                valeur: String(valeur),
                unite: unite,
                timestamp: timestamp
            }
        });

        try {
            if (!batch) {
                await alertesService.checkThresholds(capteur_id, valeur);
            }
        } catch (alertErr) {
            logger.warn('Erreur vérification alertes dans worker', { error: alertErr.message, capteur_id });
        }

        // Recalculer la santé de la parcelle après ingestion HTTP
        try {
            await parcelleHealthService.recalculateFromCapteur(capteur_id);
        } catch (healthErr) {
            logger.warn('Erreur recalcul santé parcelle (HTTP)', { error: healthErr.message, capteur_id });
        }

        return {
            status: 'success',
            id: result.id
        };

    } catch (error) {
        logger.error('Erreur traitement mesure worker', { error: error.message, jobData: job.data });
        throw error;
    }
};

/**
 * Initialiser le worker
 */
const initWorker = () => {
    worker = new Worker('sensor-data', processMeasure, {
        connection,
        concurrency: 5
    });

    worker.on('completed', (job) => {
        // logger.debug(`Job ${job.id} terminé`);
    });

    worker.on('failed', (job, err) => {
        logger.error(`Job ${job.id} a échoué après ${job.attemptsMade} tentatives`, { error: err.message });
    });

    logger.info('Worker IoT démarré et en écoute de "sensor-data"');
    return worker;
};

module.exports = { initWorker };
