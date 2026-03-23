const prisma = require('./config/prisma');
const logger = require('./utils/logger');
const config = require('./config');
// const { initWorker } = require('./workers/sensorWorker'); // REDIS DISABLED

let workerInstance;

const shutdown = async (signal) => {
  logger.info(`Worker shutdown signal received: ${signal}`);

  if (workerInstance) {
    // await workerInstance.close(); // REDIS DISABLED
    logger.info('Worker stopped');
  }

  await prisma.$disconnect();
  logger.info('Prisma disconnected for worker');
  process.exit(0);
};

const startWorker = async () => {
  try {
    await prisma.$connect();
    logger.info('Prisma connected for worker');

    // REDIS IS DISABLED - Worker is not started
    // Redis/BullMQ was causing connection issues and isn't essential
    if (!config.redis.enabled) {
      logger.warn('Worker not started: Redis is disabled.');
      logger.warn('For async job processing, enable Redis and uncommment the initWorker call.');
      // Exit gracefully - this is expected
      process.exit(0);
    }

    // This code path won't be reached since Redis is disabled
    // workerInstance = initWorker();
    // if (!workerInstance) {
    //   logger.error('Worker not started. Set REDIS_ENABLED=true for worker service.');
    //   process.exit(1);
    // }

    logger.info('AgroSmart worker started and listening for jobs');
  } catch (error) {
    logger.error('Worker startup failed', { error: error.message });
    process.exit(1);
  }
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception in worker', { error: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled rejection in worker', { reason });
});

startWorker();
