/**
 * PM2 Ecosystem Configuration - AgriSmart CI
 * Déploiement sans Docker (Nginx + PM2)
 *
 * Usage :
 *   pm2 start ecosystem.config.js
 *   pm2 save
 *   pm2 startup
 */

module.exports = {
    apps: [
        // =============================================
        // BACKEND - Node.js / Express / Prisma
        // =============================================
        {
            name: 'agrismart-backend',
            script: 'src/server.js',
            cwd: './backend',
            instances: 'max',          // Cluster mode : utilise tous les CPU
            exec_mode: 'cluster',
            watch: false,
            max_memory_restart: '500M',
            env: {
                NODE_ENV: 'production',
                PORT: 3600
            },
            error_file: './logs/pm2/backend-error.log',
            out_file: './logs/pm2/backend-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            merge_logs: true,
            // Redémarrage automatique en cas de crash
            autorestart: true,
            restart_delay: 4000,
            max_restarts: 10
        },

        // =============================================
        // FRONTEND - Next.js
        // =============================================
        {
            name: 'agrismart-frontend',
            script: 'node_modules/.bin/next',
            args: 'start -p 3601',
            cwd: './frontend',
            instances: 1,              // Next.js gère sa propre concurrence
            exec_mode: 'fork',
            watch: false,
            max_memory_restart: '400M',
            env: {
                NODE_ENV: 'production',
                PORT: 3601
            },
            error_file: './logs/pm2/frontend-error.log',
            out_file: './logs/pm2/frontend-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            autorestart: true,
            restart_delay: 3000,
            max_restarts: 10
        },

        // =============================================
        // IOT SERVICE - Node.js / MQTT / BullMQ
        // =============================================
        {
            name: 'agrismart-iot',
            script: 'index.js',
            cwd: './iot_service',
            instances: 1,
            exec_mode: 'fork',
            watch: false,
            max_memory_restart: '200M',
            env: {
                NODE_ENV: 'production',
                PORT: 4000,
                // Redis doit être installé localement si ce service est actif
                REDIS_HOST: '127.0.0.1',
                REDIS_PORT: 6379
            },
            error_file: './logs/pm2/iot-error.log',
            out_file: './logs/pm2/iot-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            autorestart: true,
            restart_delay: 5000,
            max_restarts: 5
        },

        // =============================================
        // AI SERVICE - Python / Flask / Gunicorn
        // =============================================
        // IMPORTANT : Gunicorn doit être installé dans le venv Python
        // Le service AI tourne sur le port 5001
        {
            name: 'agrismart-ai',
            script: 'gunicorn',
            args: '--workers 2 --bind 127.0.0.1:5001 app:app',
            cwd: './ai_service',
            interpreter: './.venv/bin/python3',  // Adapter selon le chemin du venv
            instances: 1,
            exec_mode: 'fork',
            watch: false,
            max_memory_restart: '600M',
            env: {
                PYTHONUNBUFFERED: '1',
                FLASK_ENV: 'production'
            },
            error_file: './logs/pm2/ai-error.log',
            out_file: './logs/pm2/ai-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            autorestart: true,
            restart_delay: 5000,
            max_restarts: 5
        }
    ]
};
