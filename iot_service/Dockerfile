# ========================================
# Dockerfile - IoT Service
# AgriSmart CI - Gateway IoT
# ========================================

FROM node:20-alpine

# Informations de build
LABEL maintainer="AgriSmart CI Team"
LABEL description="IoT Gateway Service for AgriSmart CI"

# Dossier de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production

# Copier le code source
COPY . .

# Variables d'environnement par défaut
ENV NODE_ENV=production
ENV PORT=4000

# Exposer le port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:4000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); });"

# Démarrage
CMD ["node", "index.js"]
