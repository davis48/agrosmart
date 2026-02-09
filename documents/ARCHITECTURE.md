# AgroSmart CI - Architecture & Workflows

## Vue d'ensemble de l'Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                      │
│  ┌──────────────────┐    ┌──────────────────┐                      │
│  │  📱 Mobile App    │    │  🌐 Dashboard Web │                      │
│  │  (Flutter/Dart)   │    │  (Next.js 16)     │                      │
│  │  iOS + Android    │    │  Port: 3001       │                      │
│  └────────┬─────────┘    └────────┬─────────┘                      │
└───────────┼──────────────────────┼──────────────────────────────────┘
            │ REST/WebSocket       │ REST/WebSocket
            ▼                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     NGINX REVERSE PROXY                             │
│                       Port: 80/443                                  │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│ 🚀 Backend API    │ │ 📡 IoT Service│ │ 🧠 AI Service     │
│ (Express.js)     │ │ (MQTT GW)    │ │ (FastAPI)        │
│ Prisma ORM       │ │ Port: 4000   │ │ TensorFlow       │
│ Port: 3000       │ │ MQTT: 1883   │ │ Port: 5001       │
│                  │ │              │ │                  │
│ • Auth JWT       │ │ • Mosquitto  │ │ • Diagnostic     │
│ • Marketplace    │ │ • InfluxDB   │ │ • Classification │
│ • Parcelles      │ │ • Alertes    │ │ • Prédictions    │
│ • Météo          │ │ • Capteurs   │ │                  │
│ • Communauté     │ │              │ │                  │
│ • Formations     │ │              │ │                  │
│ • Messages       │ │              │ │                  │
│ • Notifications  │ │              │ │                  │
└───────┬──────────┘ └──────┬───────┘ └──────────────────┘
        │                   │
        ▼                   ▼
┌──────────────────┐ ┌──────────────────┐
│ 🗄️ MySQL          │ │ 📊 InfluxDB       │
│ (Données métier) │ │ (Séries tempo.)  │
│ Port: 3306       │ │ Port: 8086       │
├──────────────────┤ └──────────────────┘
│ ⚡ Redis           │
│ (Cache/Queues)   │
│ Port: 6379       │
└──────────────────┘
```

## Stack Technique

| Composant | Technologie | Version |
|-----------|------------|---------|
| Frontend Web | Next.js + TypeScript + Tailwind CSS v4 | 16.1.6 |
| Mobile | Flutter/Dart | 3.x |
| Backend API | Node.js + Express.js | 22.x |
| ORM | Prisma | 6.x |
| Base de données | MySQL | 8.x |
| Cache | Redis | 7.x |
| IoT Broker | Mosquitto (MQTT) | 2.x |
| Séries temporelles | InfluxDB | 2.x |
| IA/ML | Python + FastAPI + TensorFlow | 3.12 |
| Orchestration | Docker Compose | 2.x |
| State Management (Web) | Zustand | 5.x |
| State Management (Mobile) | BLoC | 9.x |

## Containers Docker

| Container | Image | Port Exposé | Dépendances |
|-----------|-------|-------------|-------------|
| `agrismart_frontend` | `agriculture-frontend` | 3001 | api |
| `agrismart_api` | `agriculture-backend` | 3000 | mysql, redis |
| `agrismart_mysql` | `mysql:8` | 3306 | - |
| `agrismart_redis` | `redis:7-alpine` | 6379 | - |
| `agrismart_iot` | `agriculture-iot_service` | 4000 | mosquitto, api |
| `agrismart_mosquitto` | `eclipse-mosquitto` | 1883, 9001 | - |
| `agrismart_influxdb` | `influxdb:2` | 8086 | - |
| `agrismart_ai` | `agriculture-ai_service` | 5001 | - |
| `agrismart_phpmyadmin` | `phpmyadmin` | 8080 | mysql |

## Base de Données (MySQL)

### Tables principales

| Table | Description |
|-------|------------|
| `users` | Utilisateurs (ADMIN, AGRONOME, PRODUCTEUR, ACHETEUR, FOURNISSEUR, CONSEILLER, PARTENAIRE) |
| `parcelles` | Parcelles agricoles avec géolocalisation |
| `cultures` | Cultures en cours sur les parcelles |
| `capteurs` | Capteurs IoT assignés aux parcelles |
| `mesures` | Mesures physiques (température, humidité, pH, NPK) |
| `alertes` | Alertes générées par les capteurs/IA |
| `diagnostics` | Diagnostics IA sur les cultures |
| `produits` | Produits du marketplace |
| `commandes` | Commandes marketplace |
| `messages` | Messages entre utilisateurs |
| `discussions` | Fils de discussion communautaires |
| `formations` | Contenus de formation agricole |
| `recommandations` | Recommandations IA personnalisées |

### Rôles utilisateurs

| Rôle | Accès |
|------|-------|
| `ADMIN` | Dashboard admin, gestion complète |
| `PRODUCTEUR` | Parcelles, capteurs, marketplace (vente), dashboards |
| `ACHETEUR` | Marketplace (achat), communauté |
| `AGRONOME` | Diagnostics, recommandations, conseil |
| `FOURNISSEUR` | Marketplace (fournitures), catalogue |
| `CONSEILLER` | Formations, communauté, support |
| `PARTENAIRE` | Accès limité, rapports |

## API REST

Base URL: `/api/v1/`

### Endpoints principaux

| Méthode | Route | Description |
|---------|-------|------------|
| POST | `/auth/login` | Connexion (email ou téléphone) |
| POST | `/auth/register` | Inscription |
| GET | `/parcelles` | Liste des parcelles |
| GET | `/capteurs` | Liste des capteurs |
| GET | `/mesures` | Mesures des capteurs |
| GET | `/weather/current` | Météo actuelle |
| GET | `/weather/forecast` | Prévisions météo |
| GET | `/marketplace/produits` | Produits marketplace |
| GET | `/formations` | Formations disponibles |
| GET | `/communaute/discussions` | Discussions communautaires |
| POST | `/diagnostic/analyze` | Analyse IA d'une image |
| GET | `/recommandations` | Recommandations personnalisées |
| GET | `/alertes` | Alertes actives |

---

## Dernière mise à jour

- **Date** : Février 2025
- **Logo** : AgroSmart officiel (extrait de AGRO_105008.pdf)
- **Dépendances** : Toutes à jour, 0 vulnérabilités (frontend & backend)
- **Tailwind CSS** : Migré vers syntaxe v4 (`bg-linear-to-*`, `shrink-0`, etc.)
- **@types/recharts** : Supprimé (recharts v3 inclut ses propres types)
