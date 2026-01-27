# ============================================
# AgriSmart CI - Backend API Dockerfile (Development)
# Optimisé pour le layer caching et rebuild rapide
# Base de données: MySQL avec Prisma ORM
# ============================================

FROM node:20-slim AS base

# Installer les dépendances système (mutualisé et caché)
RUN apt-get update && apt-get install -y \
    openssl \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /app

# ============================================
# Stage: Dependencies
# Optimisé pour maximiser le cache Docker
# ============================================
FROM base AS dependencies

# 1. Copier UNIQUEMENT les fichiers de lock et manifest
# Ceci permet de cacher ce layer si les dépendances ne changent pas
COPY package.json package-lock.json ./

# 2. Installer les dépendances (cache si package*.json inchangé)
RUN npm ci

# 3. Copier le schema Prisma APRÈS npm ci (évite rebuild si prisma change)
COPY prisma ./prisma/

# 4. Générer le client Prisma (cache si schema.prisma inchangé)
RUN npx prisma generate

# ============================================
# Stage: Development (avec hot reload)
# ============================================
FROM dependencies AS development

# Copier le code source (layer séparé, invalidé à chaque changement)
COPY . .

# Créer les répertoires avec bonnes permissions
RUN mkdir -p uploads logs uploads/profiles uploads/diagnostics && \
    chown -R node:node /app

# Utiliser node user pour la sécurité
USER node

EXPOSE 3000

ENV NODE_ENV=development
ENV PORT=3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
