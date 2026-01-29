# 🐳 Guide d'Installation Docker - AgriSmart CI

Ce guide détaille les étapes pour initialiser et lancer le projet AgriSmart CI sur une nouvelle machine en utilisant Docker.

## 📋 Prérequis

- **Docker** et **Docker Compose** installés sur la machine.
- Git installé.
- Le dépôt cloné localement.

## 🚀 Installation & Lancement

### 1. Configuration des Variables d'Environnement

Le projet utilise un fichier `.env` unique pour l'orchestration Docker.

1. Copiez le modèle `.env.docker.example` vers `.env` :
   ```bash
   cp .env.docker.example .env
   ```

2. **IMPORTANT** : Ouvrez le fichier `.env` et remplacez les valeurs `<PLACEHOLDER>` par des mots de passe sécurisés.
   - Vous pouvez générer des chaînes aléatoires pour les secrets.
   - Exemple pour MySQL, Redis, InfluxDB, etc.

### 2. Lancement des Conteneurs

Compilez et démarrez tous les services en arrière-plan :

```bash
docker compose up -d --build
```

> ☕ La première compilation peut prendre quelques minutes.

Vérifiez que tous les conteneurs sont "healthy" ou "running" :

```bash
docker compose ps
```

### 3. Initialisation de la Base de Données

Une fois les conteneurs lancés (attendez que `agrismart_mysql` soit prêt), initialisez le schéma de base de données :

```bash
docker compose exec api npm run db:migrate:dev
```

Optionnel : Pour charger des données de test (seeds) :

```bash
docker compose exec api npm run db:seed
```

## 🌐 Accès aux Services

Une fois lancé, le projet est accessible aux adresses suivantes :

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | `http://localhost:3001` | Interface Web Utilisateur |
| **Backend API** | `http://localhost:3000` | API REST |
| **PhpMyAdmin** | `http://localhost:8080` | Gestion BDD MySQL |
| **IoT Service** | `http://localhost:4000` | Service IoT |
| **AI Service** | `http://localhost:5001` | Service IA |

## 🛠 Commandes Utiles

- **Arrêter les services** :
  ```bash
  docker compose down
  ```

- **Voir les logs (ex: backend)** :
  ```bash
  docker compose logs -f api
  ```

- **Redémarrer un service (ex: frontend)** :
  ```bash
  docker compose restart frontend
  ```

- **Accéder au shell d'un conteneur** :
  ```bash
  docker compose exec api /bin/bash
  ```

## 🐛 Dépannage

- **Erreur de connexion DB** : Vérifiez que `agrismart_mysql` est "healthy". Si nécessaire, redémarrez l'API : `docker compose restart api`.
- **Ports occupés** : Assurez-vous que les ports 3000, 3001, 3306, 6379, 8080 ne sont pas déjà utilisés.
