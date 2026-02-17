# 🌾 AgroSmart CI - Plateforme Agricole Intelligente

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-22.x-green.svg)](https://nodejs.org/)
[![Next.js](https://img.shields.io/badge/Next.js-16.x-black.svg)](https://nextjs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)](https://www.docker.com/)

## 📋 Table des matières

- [À propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Architecture](#-architecture)
- [Technologies](#-technologies)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [Scripts disponibles](#-scripts-disponibles)
- [Déploiement](#-déploiement)
- [Tests](#-tests)
- [API Documentation](#-api-documentation)
- [Structure du projet](#-structure-du-projet)
- [Contribution](#-contribution)
- [Licence](#-licence)

## 📖 À propos

**AgroSmart CI** est une plateforme agricole intelligente développée pour la Côte d'Ivoire, intégrant des technologies IoT, Intelligence Artificielle et analyses prédictives pour optimiser la production agricole.

La plateforme permet aux agriculteurs de :
- Surveiller leurs parcelles en temps réel via des capteurs IoT
- Recevoir des recommandations basées sur l'IA
- Gérer leurs cultures et optimiser les rendements
- Accéder à un marketplace agricole
- Participer à des coopératives
- Suivre les performances et le ROI

## ✨ Fonctionnalités

### 🌱 Gestion des Parcelles
- **Création et suivi** de parcelles agricoles géolocalisées
- **Calcul automatique** de santé et rendement des parcelles
- **Historique complet** des cultures et récoltes
- **Progression des cultures** avec notifications automatiques

### 📡 IoT & Capteurs
- **Stations météo** connectées avec capteurs multiples
- **Surveillance temps réel** : température, humidité, pH du sol, luminosité
- **Alertes automatiques** en cas d'anomalies
- **Stockage TimeSeries** avec InfluxDB pour analyses historiques
- **Communication MQTT** pour les devices IoT

### 🤖 Intelligence Artificielle
- **Diagnostic de maladies** via analyse d'images (TensorFlow)
- **Recommandations d'irrigation** basées sur données environnementales
- **Prédictions de rendement** utilisant ML
- **Classes de maladies** : Saine, Rouille, Tache Foliaire, Mildiou

### 🏪 Marketplace
- **Achat/vente** de produits agricoles
- **Gestion des stocks** en temps réel
- **Wishlist** et favoris
- **Système de notation** et avis

### 👥 Gestion des Utilisateurs
- **Multi-rôles** : Admin, Agronome, Producteur, Acheteur, Partenaire
- **Authentification sécurisée** (JWT + bcrypt)
- **Profils enrichis** avec statistiques
- **Coopératives** et adhésions

### 📊 Analytics & Rapports
- **Tableaux de bord** interactifs
- **Statistiques de performance** et économies réalisées
- **Calculs de ROI** automatiques
- **Exports de données** (PDF, Excel)
- **Graphiques temps réel** avec Recharts

### 📱 Applications Multiplateformes
- **Web App** responsive (Next.js)
- **Mobile App** native (Flutter) - iOS & Android
- **API RESTful** complète
- **WebSocket** pour notifications temps réel

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NGINX Reverse Proxy                      │
│              (Load Balancing, SSL, Rate Limiting)            │
└───────┬─────────────────────────────────────────────┬───────┘
        │                                             │
        ▼                                             ▼
┌──────────────────┐                         ┌──────────────────┐
│   Frontend       │                         │   Mobile App     │
│   (Next.js)      │                         │   (Flutter)      │
│   Port 3001      │                         │   iOS/Android    │
└────────┬─────────┘                         └────────┬─────────┘
         │                                            │
         └────────────────────┬───────────────────────┘
                              ▼
                    ┌──────────────────┐
                    │   Backend API    │
                    │   (Node.js)      │
                    │   Port 3000      │
                    └────────┬─────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐  ┌──────────────┐  ┌─────────────────┐
│   MySQL 8.4     │  │  Redis 7.4   │  │  InfluxDB 2.7   │
│   (Database)    │  │  (Cache)     │  │  (IoT Metrics)  │
└─────────────────┘  └──────────────┘  └─────────────────┘
         │
         ▼
┌─────────────────┐  ┌──────────────┐  ┌─────────────────┐
│  AI Service     │  │ IoT Service  │  │  Mosquitto      │
│  (Python/TF)    │  │ (Node.js)    │  │  (MQTT Broker)  │
│  Port 5000      │  │ Port 4000    │  │  Port 1883      │
└─────────────────┘  └──────────────┘  └─────────────────┘
```

### Composants Principaux

1. **Backend API** (Node.js + Express)
   - API RESTful avec Express 5
   - ORM Prisma pour MySQL
   - WebSocket (Socket.IO) pour temps réel
   - Workers BullMQ pour tâches asynchrones
   - Rate limiting et sécurité

2. **Frontend Web** (Next.js 16)
   - SSR/SSG pour performances optimales
   - UI moderne avec Tailwind CSS 4
   - State management avec Zustand
   - Formulaires avec React Hook Form + Zod
   - Graphiques avec Recharts

3. **Mobile App** (Flutter)
   - Architecture BLoC pattern
   - Navigation fluide
   - Gestion d'état avec flutter_bloc
   - API client avec Dio
   - Graphiques avec fl_chart

4. **AI Service** (Python + Flask)
   - Modèles TensorFlow pour diagnostic maladies
   - Prédictions d'irrigation
   - API REST pour inférence
   - Support images (PNG, JPG, WEBP)

5. **IoT Service** (Node.js)
   - Broker MQTT Mosquitto
   - Ingestion données capteurs
   - Stockage InfluxDB
   - Alertes automatiques

## 🛠 Technologies

### Backend
- **Runtime** : Node.js 22.x
- **Framework** : Express 5.2
- **ORM** : Prisma 6.9
- **Database** : MySQL 8.4
- **Cache** : Redis 7.4
- **Queue** : BullMQ
- **WebSocket** : Socket.IO 4.8
- **Auth** : JWT + bcryptjs
- **Validation** : express-validator + Joi
- **Logging** : Winston
- **Testing** : Jest

### Frontend
- **Framework** : Next.js 16.1 (React 19)
- **UI** : Tailwind CSS 4, Radix UI
- **State** : Zustand 5
- **Forms** : React Hook Form + Zod
- **HTTP** : Axios
- **Charts** : Recharts
- **i18n** : i18next
- **Animations** : Framer Motion

### Mobile
- **Framework** : Flutter 3.10+
- **Language** : Dart 3.10+
- **State** : flutter_bloc 9.1
- **HTTP** : Dio 5.4
- **Charts** : fl_chart 1.1

### AI/ML
- **Framework** : TensorFlow 2.x
- **Web** : Flask
- **Image** : Pillow (PIL)
- **Compute** : NumPy

### Infrastructure
- **Containerization** : Docker + Docker Compose
- **Web Server** : Nginx Alpine
- **SSL** : Certbot (Let's Encrypt)
- **IoT** : Mosquitto MQTT, InfluxDB 2.7
- **CI/CD** : GitHub Actions (à venir)

## 📦 Prérequis

### Développement Local (sans Docker)
- **Node.js** : v22.x ou supérieur
- **npm** : v10.x ou supérieur
- **MySQL** : v8.0 ou supérieur
- **Redis** : v7.x ou supérieur
- **Python** : v3.11+ (pour AI service)
- **Flutter** : v3.10+ (pour mobile)
- **Git** : v2.x

### Développement avec Docker (recommandé)
- **Docker** : v24.x ou supérieur
- **Docker Compose** : v2.20 ou supérieur
- **Git** : v2.x

### Production
- **Serveur VPS** : 16GB RAM, 4 vCPU minimum (ex: Hostinger KVM 4)
- **OS** : Ubuntu 22.04 LTS (recommandé) / Debian 11+ / CentOS 8+
- **Docker** + **Docker Compose**
- **Ports requis** : 80, 443, 3000, 3001, 1883, 8086

## 🚀 Installation

### 1. Cloner le dépôt

```bash
# Cloner le projet
git clone https://github.com/davis48/agrosmart.git

# Accéder au répertoire
cd agrosmart
```

### 2. Installation avec Docker (Recommandé)

#### a) Configuration initiale

```bash
# Copier le fichier d'environnement exemple
cp .env.example .env

# Éditer le fichier .env avec vos valeurs
nano .env  # ou vim, code, etc.
```

**Variables obligatoires dans `.env` :**

```bash
# Base de données
MYSQL_ROOT_PASSWORD=VotreMotDePasseRootTrèsFort123!
MYSQL_PASSWORD=VotreMotDePasseUserFort456!
DATABASE_URL="mysql://agrismart:VotreMotDePasseUserFort456!@mysql:3306/agrismart_ci"

# Redis
REDIS_PASSWORD=VotreMotDePasseRedisFort789!

# JWT
JWT_SECRET=VotreCléSecrèteJWTTrèsLongueEtComplexe123456789!
JWT_REFRESH_SECRET=VotreCléSecrèteRefreshJWTEncore PlusLongue987654321!

# InfluxDB
INFLUXDB_PASSWORD=VotreMotDePasseInfluxDBFort123!
INFLUXDB_TOKEN=VotreTokenInfluxDBTrèsLongEtComplexe123456789!

# Admin (premier déploiement)
ADMIN_PASSWORD=AdminSecure@2024!
SEED_DEFAULT_PASSWORD=DevSeed@2024!

# Environnement
NODE_ENV=development
RUN_SEED=false  # true uniquement pour premier déploiement
```

#### b) Démarrer tous les services

```bash
# Construire et démarrer tous les conteneurs
docker compose up -d

# Vérifier que tous les services sont running
docker compose ps

# Voir les logs en temps réel
docker compose logs -f
```

#### c) Initialiser la base de données (premier démarrage)

```bash
# Attendre que MySQL soit prêt (30-60 secondes)
docker compose logs -f mysql

# Les migrations Prisma s'exécutent automatiquement au démarrage du backend
# Pour vérifier :
docker compose logs api | grep "Migration"

# Pour seeder la base (optionnel, données de test)
docker compose exec api npm run db:seed
```

#### d) Accéder aux services

- **Frontend** : http://localhost:3001
- **Backend API** : http://localhost:3000/api/v1
- **PhpMyAdmin** : http://localhost:8080
- **InfluxDB UI** : http://localhost:8086
- **API Docs** : http://localhost:3000/api/v1/docs (à venir)

### 3. Installation Manuelle (sans Docker)

#### a) Backend

```bash
cd backend

# Installer les dépendances
npm install

# Copier le fichier d'environnement
cp .env.example .env

# Éditer .env avec vos valeurs (DATABASE_URL, etc.)
nano .env

# Générer le client Prisma
npx prisma generate

# Exécuter les migrations
npm run db:migrate:dev

# (Optionnel) Seeder la base
npm run db:seed

# Démarrer en mode développement
npm run dev
```

#### b) Frontend

```bash
cd frontend

# Installer les dépendances
npm install

# Copier le fichier d'environnement
cp .env.local.example .env.local

# Éditer .env.local
nano .env.local

# Démarrer le serveur dev
npm run dev
```

#### c) AI Service

```bash
cd ai_service

# Créer un environnement virtuel Python
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Installer les dépendances
pip install -r requirements.txt

# Démarrer le service
python app.py
```

#### d) Mobile App

```bash
cd mobile

# Installer les dépendances Flutter
flutter pub get

# Vérifier la configuration
flutter doctor

# Lancer sur émulateur/device
flutter run
```

## ⚙️ Configuration

### Variables d'environnement Backend

Créez un fichier `backend/.env` basé sur `backend/.env.example` :

```bash
# Serveur
NODE_ENV=development
PORT=3000
CORS_ORIGIN=http://localhost:3001

# Base de données
DATABASE_URL="mysql://user:password@localhost:3306/agrosmart_ci"

# JWT
JWT_SECRET=votre_secret_jwt_très_long_et_complexe
JWT_REFRESH_SECRET=votre_secret_refresh_jwt_encore_plus_long
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=votre_password_redis

# InfluxDB
INFLUXDB_URL=http://localhost:8086
INFLUXDB_TOKEN=votre_token_influxdb
INFLUXDB_ORG=agrismart
INFLUXDB_BUCKET=sensors

# AI Service
AI_SERVICE_URL=http://localhost:5000

# IoT
MQTT_BROKER_URL=mqtt://localhost:1883

# Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760

# Email (optionnel)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Logging
LOG_LEVEL=info
LOG_DIR=./logs
```

### Variables d'environnement Frontend

Créez un fichier `frontend/.env.local` :

```bash
# API Backend
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
NEXT_PUBLIC_SOCKET_URL=http://localhost:3000

# App
NEXT_PUBLIC_APP_NAME=AgroSmart CI
NEXT_PUBLIC_APP_VERSION=1.0.0

# Maps (optionnel)
NEXT_PUBLIC_MAPBOX_TOKEN=your_mapbox_token
```

### Configuration Mobile

Éditez `mobile/lib/core/config/app_config.dart` :

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
  // Ou 'http://localhost:3000/api/v1' pour iOS simulator
  // Ou 'http://YOUR_IP:3000/api/v1' pour device physique
  
  static const String socketUrl = 'http://10.0.2.2:3000';
}
```

## 💻 Utilisation

### Démarrage rapide avec Docker

```bash
# Démarrer tous les services
docker compose up -d

# Arrêter tous les services
docker compose down

# Redémarrer un service spécifique
docker compose restart api

# Voir les logs d'un service
docker compose logs -f api

# Reconstruire après modification du code
docker compose up -d --build
```

### Développement sans Docker

**Terminal 1 - Backend** :
```bash
cd backend
npm run dev
```

**Terminal 2 - Frontend** :
```bash
cd frontend
npm run dev
```

**Terminal 3 - AI Service** :
```bash
cd ai_service
source venv/bin/activate
python app.py
```

**Terminal 4 - Mobile** :
```bash
cd mobile
flutter run
```

### Accès à la plateforme

1. **Créer un compte** : http://localhost:3001/register
2. **Se connecter** : http://localhost:3001/login
3. **Dashboard** : http://localhost:3001/dashboard

### Compte Administrateur par défaut (après seed)

```
Email: admin@agrosmart.ci
Password: Admin@2024! (À CHANGER immédiatement)
```

## 📜 Scripts disponibles

### Backend (`backend/`)

```bash
# Développement
npm run dev                    # Démarrer avec nodemon (auto-reload)
npm start                      # Démarrer en production

# Base de données
npm run db:migrate             # Appliquer migrations (production)
npm run db:migrate:dev         # Créer/appliquer migrations (dev)
npm run db:seed                # Peupler la base avec données de test
npm run db:reset               # Réinitialiser complètement la base
npm run db:push                # Synchroniser schema sans migration
npm run db:studio              # Ouvrir Prisma Studio (GUI)

# Tests
npm test                       # Exécuter tests avec coverage
npm run test:watch             # Tests en mode watch
npm run test:docker            # Tests dans container Docker
npm run test:security          # Audit de sécurité personnalisé

# Qualité du code
npm run lint                   # Vérifier le code avec ESLint
npm run lint:fix               # Corriger automatiquement
npm run audit:security         # Audit npm avec rapport personnalisé
npm run audit:deps             # Audit de dépendances

# Docker
npm run docker:dev             # Démarrer stack dev
npm run docker:prod            # Démarrer stack production
npm run docker:down            # Arrêter tous les containers
```

### Scripts utilitaires Backend (`backend/scripts/`)

```bash
# Seeding
node scripts/seed.js                    # Seed basique
node scripts/seed-all-data.js           # Seed complet (7 régions, coop, cultures)
node scripts/seed-complete.js           # Seed ultra-complet (1700+ lignes)
node scripts/seed-iot-capteurs.js       # Seed capteurs IoT
node scripts/seed_admin.js              # Créer compte admin
node scripts/seed_economies.js          # Seed économies réalisées
node scripts/seed_marketplace.js        # Seed marketplace
node scripts/seed_performance_roi.js    # Seed performances ROI

# Maintenance
node scripts/db-maintenance.js          # Maintenance DB (optimisation, cleanup)
node scripts/recalculate-health.js      # Recalculer santé parcelles
node scripts/count-tables.js            # Compter enregistrements tables

# Tests & Audit
node scripts/verify_api_contract.js     # Vérifier contrat API
node scripts/security-audit.js          # Audit sécurité complet
node scripts/npm-audit.js               # Audit dépendances avec rapport

# Réinitialisation
psql -U agrismart -d agrismart_ci -f scripts/clean-database.sql  # Nettoyer DB
```

### Frontend (`frontend/`)

```bash
npm run dev        # Démarrer serveur dev (port 3001)
npm run build      # Build production optimisé
npm start          # Démarrer serveur production
npm run lint       # Vérifier code avec ESLint
```

### Mobile (`mobile/`)

```bash
# Développement
flutter run                    # Lancer sur device/emulator
flutter run -d chrome          # Lancer sur Chrome
flutter run --release          # Build release

# Tests
flutter test                   # Exécuter tests unitaires
flutter test --coverage        # Tests avec coverage

# Build
flutter build apk              # Build APK Android
flutter build appbundle        # Build App Bundle Android
flutter build ios              # Build iOS (macOS uniquement)
flutter build web              # Build Web

# Maintenance
flutter pub get                # Installer dépendances
flutter pub upgrade            # Mettre à jour dépendances
flutter clean                  # Nettoyer build
flutter doctor                 # Vérifier configuration
bash clean_flutter.sh          # Script de nettoyage complet
```

### Scripts de déploiement (`scripts/`)

```bash
# Déploiement Hostinger VPS
bash scripts/deploy-hostinger.sh        # Déploiement automatisé complet
bash scripts/init-ssl.sh domain.com email@domain.com  # Configuration SSL

# Tests IoT
bash seed-iot-quick.sh                  # Seed rapide IoT
bash test-iot.sh                        # Tester système IoT
```

## 🚀 Déploiement

### Déploiement sur Hostinger VPS (Production)

Le projet inclut un script de déploiement automatisé pour Hostinger VPS.

#### Prérequis

- VPS Hostinger KVM 4 (16GB RAM, 4 vCPU) ou supérieur
- Ubuntu 22.04 LTS
- Accès SSH root
- (Optionnel) Nom de domaine pointant vers le VPS

#### Procédure complète

**1. Connexion au VPS**

```bash
ssh root@VOTRE_IP_VPS
```

**2. Cloner le projet**

```bash
cd /opt
git clone https://github.com/davis48/agrosmart.git
cd agrosmart
```

**3. Exécuter le script de déploiement**

```bash
bash scripts/deploy-hostinger.sh
```

Le script effectue automatiquement :
- ✅ Installation de Docker et Docker Compose
- ✅ Configuration du pare-feu (UFW/firewalld)
- ✅ Génération de mots de passe sécurisés
- ✅ Configuration de l'environnement (.env)
- ✅ Construction des images Docker
- ✅ Démarrage des services avec healthchecks
- ✅ Exécution des migrations Prisma
- ✅ (Optionnel) Seeding de la base de données

**4. Vérification**

```bash
# Vérifier les services
docker compose -f docker-compose.hostinger.yml ps

# Voir les logs
docker compose -f docker-compose.hostinger.yml logs -f

# Vérifier l'accès web
curl http://VOTRE_IP_VPS
```

**5. Accéder à l'application**

- **Web App** : `http://VOTRE_IP_VPS`
- **API** : `http://VOTRE_IP_VPS/api/v1`

#### Configuration SSL (Let's Encrypt)

Une fois votre domaine configuré :

```bash
cd /opt/agrosmart
bash scripts/init-ssl.sh votredomaine.com votre@email.com
```

Le script :
- ✅ Vérifie la configuration DNS
- ✅ Obtient le certificat SSL via Certbot
- ✅ Configure Nginx avec HTTPS
- ✅ Met en place le renouvellement automatique (cron)
- ✅ Redirige HTTP → HTTPS

Accès sécurisé : `https://votredomaine.com`

#### Maintenance Production

```bash
# Voir les logs
docker compose -f docker-compose.hostinger.yml logs -f api

# Redémarrer un service
docker compose -f docker-compose.hostinger.yml restart api

# Mise à jour du code
cd /opt/agrosmart
git pull origin main
docker compose -f docker-compose.hostinger.yml up -d --build

# Backup base de données
docker compose -f docker-compose.hostinger.yml exec mysql \
  mysqldump -u root -p agrismart_ci > backup_$(date +%Y%m%d).sql

# Restaurer backup
docker compose -f docker-compose.hostinger.yml exec -T mysql \
  mysql -u root -p agrismart_ci < backup_20260217.sql
```

### Autres plateformes

#### DigitalOcean / AWS EC2 / Azure VM

Les étapes sont similaires à Hostinger :

```bash
# 1. Connexion SSH
ssh user@YOUR_SERVER_IP

# 2. Cloner
git clone https://github.com/davis48/agrosmart.git
cd agrosmart

# 3. Adapter docker-compose.hostinger.yml si nécessaire
cp docker-compose.hostinger.yml docker-compose.prod.yml

# 4. Configurer .env
cp .env.production.example .env
nano .env  # Remplir vos valeurs

# 5. Déployer
docker compose -f docker-compose.prod.yml up -d
```

#### Vercel (Frontend uniquement)

```bash
cd frontend

# Installer Vercel CLI
npm i -g vercel

# Déployer
vercel --prod

# Variables d'environnement à configurer dans Vercel Dashboard:
# NEXT_PUBLIC_API_URL
# NEXT_PUBLIC_SOCKET_URL
```

## 🧪 Tests

### Backend

```bash
cd backend

# Tests unitaires
npm test

# Tests avec coverage
npm test -- --coverage

# Tests spécifiques
npm test -- auth.test.js

# Tests en mode watch
npm run test:watch

# Tests dans Docker
npm run test:docker
```

**Dossiers de tests** :
- `tests/unit/` - Tests unitaires (services, utils)
- `tests/integration/` - Tests d'intégration (API, DB)
- `tests/services/` - Tests services métier
- `tests/load/` - Tests de charge (à venir)

**Coverage requis** : 80% minimum

### Frontend

```bash
cd frontend

# Tests à venir avec Jest + React Testing Library
# npm test
```

### Mobile

```bash
cd mobile

# Tests unitaires
flutter test

# Tests avec coverage
flutter test --coverage

# Tests spécifiques
flutter test test/features/auth_test.dart
```

## 📚 API Documentation

### Endpoints principaux

#### Authentification

```http
POST   /api/v1/auth/register           # Inscription
POST   /api/v1/auth/login              # Connexion
POST   /api/v1/auth/logout             # Déconnexion
POST   /api/v1/auth/refresh            # Refresh token
POST   /api/v1/auth/forgot-password    # Mot de passe oublié
POST   /api/v1/auth/reset-password     # Réinitialiser mot de passe
```

#### Utilisateurs

```http
GET    /api/v1/users/profile           # Profil utilisateur
PUT    /api/v1/users/profile           # Modifier profil
GET    /api/v1/users                   # Liste utilisateurs (Admin)
GET    /api/v1/users/:id               # Détails utilisateur
PUT    /api/v1/users/:id               # Modifier utilisateur (Admin)
DELETE /api/v1/users/:id               # Supprimer utilisateur (Admin)
```

#### Parcelles

```http
GET    /api/v1/parcelles               # Liste parcelles
POST   /api/v1/parcelles               # Créer parcelle
GET    /api/v1/parcelles/:id           # Détails parcelle
PUT    /api/v1/parcelles/:id           # Modifier parcelle
DELETE /api/v1/parcelles/:id           # Supprimer parcelle
GET    /api/v1/parcelles/:id/health    # Santé parcelle
GET    /api/v1/parcelles/:id/stats     # Statistiques parcelle
```

#### Cultures

```http
GET    /api/v1/cultures                # Liste cultures
POST   /api/v1/cultures                # Créer culture
GET    /api/v1/cultures/:id            # Détails culture
PUT    /api/v1/cultures/:id            # Modifier culture
DELETE /api/v1/cultures/:id            # Supprimer culture
```

#### IoT / Capteurs

```http
GET    /api/v1/stations                # Liste stations météo
POST   /api/v1/stations                # Créer station
GET    /api/v1/stations/:id            # Détails station
GET    /api/v1/stations/:id/sensors    # Capteurs d'une station
GET    /api/v1/sensors/:id/data        # Données capteur
POST   /api/v1/sensors/data            # Envoyer données (IoT devices)
```

#### IA / Diagnostics

```http
POST   /api/v1/ai/diagnose             # Diagnostic maladie (image)
POST   /api/v1/ai/irrigation           # Recommandation irrigation
GET    /api/v1/diagnostics             # Historique diagnostics
GET    /api/v1/diagnostics/:id         # Détails diagnostic
```

#### Marketplace

```http
GET    /api/v1/marketplace/products    # Liste produits
POST   /api/v1/marketplace/products    # Créer produit
GET    /api/v1/marketplace/products/:id # Détails produit
PUT    /api/v1/marketplace/products/:id # Modifier produit
DELETE /api/v1/marketplace/products/:id # Supprimer produit
POST   /api/v1/marketplace/wishlist    # Ajouter au wishlist
```

#### Coopératives

```http
GET    /api/v1/cooperatives            # Liste coopératives
POST   /api/v1/cooperatives            # Créer coopérative
GET    /api/v1/cooperatives/:id        # Détails coopérative
POST   /api/v1/cooperatives/:id/join   # Adhérer à une coopérative
```

### Format de réponse

**Succès** :
```json
{
  "success": true,
  "data": { ... },
  "message": "Opération réussie"
}
```

**Erreur** :
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Données invalides",
    "details": [ ... ]
  }
}
```

### Authentification

Toutes les routes (sauf `/auth/*`) nécessitent un token JWT :

```http
Authorization: Bearer YOUR_JWT_TOKEN
```

## 📁 Structure du projet

```
agrosmart/
├── backend/                      # API Node.js + Express
│   ├── src/
│   │   ├── config/              # Configuration (db, redis, influx, etc.)
│   │   ├── controllers/         # Contrôleurs API
│   │   ├── middlewares/         # Middlewares (auth, validation, errors)
│   │   ├── routes/              # Routes Express
│   │   ├── services/            # Logique métier
│   │   ├── utils/               # Utilitaires
│   │   ├── validators/          # Schémas de validation
│   │   ├── workers/             # Workers BullMQ
│   │   ├── server.js            # Point d'entrée
│   │   └── socket.js            # Configuration WebSocket
│   ├── prisma/
│   │   ├── schema.prisma        # Schéma Prisma
│   │   └── migrations/          # Migrations SQL
│   ├── scripts/                 # Scripts utilitaires (seed, maintenance)
│   ├── tests/                   # Tests (unit, integration, e2e)
│   ├── uploads/                 # Fichiers uploadés
│   ├── logs/                    # Logs applicatifs
│   ├── Dockerfile.prod          # Dockerfile production
│   ├── package.json
│   └── .env.example
│
├── frontend/                    # Application Web Next.js
│   ├── src/
│   │   ├── app/                 # App Router Next.js
│   │   │   ├── (auth)/         # Routes auth
│   │   │   ├── dashboard/      # Dashboard
│   │   │   ├── parcelles/      # Gestion parcelles
│   │   │   ├── marketplace/    # Marketplace
│   │   │   └── layout.tsx
│   │   ├── components/          # Composants React
│   │   │   ├── ui/             # Composants UI (Radix)
│   │   │   ├── forms/          # Formulaires
│   │   │   ├── charts/         # Graphiques
│   │   │   └── layout/         # Layout components
│   │   ├── hooks/               # Custom hooks
│   │   └── lib/                 # Utils (API client, stores)
│   ├── public/                  # Assets statiques
│   ├── Dockerfile.prod
│   ├── package.json
│   └── .env.local.example
│
├── mobile/                      # Application Mobile Flutter
│   ├── lib/
│   │   ├── core/               # Config, constantes, theme
│   │   ├── data/               # Repositories, data sources
│   │   ├── domain/             # Entities, use cases
│   │   ├── presentation/       # UI (screens, widgets, BLoC)
│   │   └── main.dart
│   ├── assets/                 # Images, traductions, audio
│   ├── test/                   # Tests Flutter
│   ├── android/                # Code natif Android
│   ├── ios/                    # Code natif iOS
│   └── pubspec.yaml
│
├── ai_service/                  # Service IA Python
│   ├── models/                 # Modèles TensorFlow (.h5)
│   ├── app.py                  # API Flask
│   ├── Dockerfile
│   └── requirements.txt
│
├── iot_service/                 # Service IoT Node.js
│   ├── config/
│   │   └── mosquitto.conf      # Config MQTT
│   ├── index.js
│   └── package.json
│
├── nginx/                       # Configuration Nginx
│   ├── nginx.conf              # Config principale
│   ├── agrismart.conf          # Config dev
│   ├── hostinger.conf          # Config production
│   └── ssl/                    # Certificats SSL
│
├── scripts/                     # Scripts de déploiement
│   ├── deploy-hostinger.sh     # Déploiement automatisé VPS
│   ├── init-ssl.sh             # Configuration SSL
│   └── pre-commit-security.sh  # Hook Git sécurité
│
├── docker-compose.yml           # Compose développement
├── docker-compose.hostinger.yml # Compose production Hostinger
├── .env.example                 # Variables d'environnement exemple
├── .gitignore
├── README.md                    # Ce fichier
├── DEPLOYMENT.md                # Guide déploiement détaillé
├── SECURITY_ACTIONS.md          # Guide sécurité
└── PRE_PUSH_CHECKLIST.md        # Checklist pré-push
```

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment contribuer :

### 1. Fork le projet

```bash
# Cliquer sur "Fork" sur GitHub
# Puis cloner votre fork
git clone https://github.com/VOTRE_USERNAME/agrosmart.git
cd agrosmart
```

### 2. Créer une branche

```bash
git checkout -b feature/ma-nouvelle-fonctionnalite
# ou
git checkout -b fix/correction-bug
```

### 3. Faire vos modifications

```bash
# Coder votre feature
# Ajouter des tests si nécessaire
# Mettre à jour la documentation
```

### 4. Vérifier la qualité

```bash
# Backend
cd backend
npm run lint          # Vérifier le code
npm test              # Lancer les tests
npm run test:security # Audit sécurité

# Frontend
cd frontend
npm run lint
```

### 5. Commit et Push

```bash
# Utiliser des messages de commit conventionnels
git add .
git commit -m "feat: ajouter fonctionnalité de notification push"

# Ou pour un fix
git commit -m "fix: corriger calcul de rendement parcelle"

# Push vers votre fork
git push origin feature/ma-nouvelle-fonctionnalite
```

### 6. Créer une Pull Request

- Aller sur GitHub
- Cliquer sur "New Pull Request"
- Décrire vos changements
- Attendre la review

### Conventions de commit

Utiliser [Conventional Commits](https://www.conventionalcommits.org/) :

- `feat:` Nouvelle fonctionnalité
- `fix:` Correction de bug
- `docs:` Documentation
- `style:` Formatage (pas de changement de code)
- `refactor:` Refactoring
- `test:` Ajout/modification de tests
- `chore:` Maintenance

### Standards de code

- **Backend** : ESLint + Prettier
- **Frontend** : ESLint + Prettier + TypeScript strict
- **Mobile** : Dart analysis_options.yaml
- **Tests** : Minimum 80% coverage pour nouvelles features
- **Documentation** : JSDoc/TSDoc pour fonctions publiques

## 🔒 Sécurité

### Signaler une vulnérabilité

Si vous découvrez une vulnérabilité de sécurité, **NE PAS** créer d'issue publique. Envoyez un email à : **security@agrosmart.ci**

### Bonnes pratiques

- ✅ Toujours utiliser des variables d'environnement pour secrets
- ✅ Ne jamais commiter de `.env` ou fichiers sensibles
- ✅ Utiliser le hook pre-commit installé (`scripts/pre-commit-security.sh`)
- ✅ Exécuter `npm run test:security` avant chaque push
- ✅ Mettre à jour régulièrement les dépendances : `npm audit`
- ✅ Changer TOUS les mots de passe par défaut en production

### Audit de sécurité

```bash
# Backend
cd backend
npm run audit:security    # Audit personnalisé
npm audit fix             # Corriger vulnérabilités auto

# Check pre-commit hook
bash scripts/pre-commit-security.sh
```

## 📄 Licence

Ce projet est sous licence **MIT**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

```
MIT License

Copyright (c) 2024-2026 AgroSmart Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 👥 Équipe

- **Lead Developer** : [@davis48](https://github.com/davis48)
- **Contributors** : Voir [CONTRIBUTORS.md](CONTRIBUTORS.md)

## 📞 Contact & Support

- **Website** : https://agrosmart.ci (à venir)
- **Email** : contact@agrosmart.ci
- **Issues** : https://github.com/davis48/agrosmart/issues
- **Discussions** : https://github.com/davis48/agrosmart/discussions

## 🙏 Remerciements

- Communauté agricole de Côte d'Ivoire
- Open source contributors
- [Prisma](https://www.prisma.io/) pour l'excellent ORM
- [Next.js](https://nextjs.org/) pour le framework React
- [Flutter](https://flutter.dev/) pour le framework mobile
- [TensorFlow](https://www.tensorflow.org/) pour les modèles IA

## 🗺 Roadmap

### Version 1.1 (Q2 2026)
- [ ] API GraphQL
- [ ] Notifications Push mobile
- [ ] Système de messagerie producteurs/agronomes
- [ ] Export rapports PDF personnalisés

### Version 1.2 (Q3 2026)
- [ ] Intégration systèmes de paiement mobile (Orange Money, MTN, Wave)
- [ ] Marketplace avec système de livraison
- [ ] Dashboard analytics avancé (Power BI style)
- [ ] Support multilingue (Français, Anglais, Baoulé, Dioula)

### Version 2.0 (Q4 2026)
- [ ] Modèles IA améliorés (détection 20+ maladies)
- [ ] Prédictions météo locale machine learning
- [ ] Système de certification bio
- [ ] Blockchain pour traçabilité produits
- [ ] Application Desktop (Electron)

---

<div align="center">

**Fait avec ❤️ en Côte d'Ivoire pour l'agriculture intelligente africaine**

[⬆ Retour en haut](#-agrosmart-ci---plateforme-agricole-intelligente)

</div>
