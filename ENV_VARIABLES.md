# ENV_VARIABLES.md — Variables d'Environnement AgroSmart CI

> Ce fichier liste **toutes** les variables d'environnement à configurer pour le déploiement.
> Ne contient **aucune donnée sensible** — il est sûr de le commiter sur Git.
>
> ⚠️ Les vraies valeurs doivent être mises uniquement dans les fichiers `.env` sur le serveur
> (ces fichiers sont dans `.gitignore` et ne seront jamais poussés sur GitHub).

---

## 📦 Backend — `backend/.env`

Copier depuis le template :
```bash
cp backend/.env.PRODUCTION_SANS_DOCKER backend/.env
nano backend/.env
```

### 🔴 Variables OBLIGATOIRES

| Variable | Description | Exemple / Format |
|----------|-------------|------------------|
| `NODE_ENV` | Mode de l'application | `production` |
| `PORT` | Port du serveur backend | `3600` ← **ne pas changer** |
| `DB_HOST` | Adresse du serveur MySQL Hostinger | `votre-serveur.hstgr.io` |
| `DB_PORT` | Port MySQL | `3306` |
| `DB_NAME` | Nom de la base de données | `votre_base_de_donnees` |
| `DB_USER` | Utilisateur MySQL | `votre_utilisateur_mysql` |
| `DB_PASSWORD` | Mot de passe MySQL | `votre_mot_de_passe_db` |
| `DATABASE_URL` | URL Prisma complète | `mysql://<USER>:<PASSWORD>@<HOST>:3306/<DB_NAME>` |
| `JWT_SECRET` | Clé secrète JWT (min 64 chars) | Générer avec la commande ci-dessous |
| `JWT_REFRESH_SECRET` | Clé secrète Refresh JWT (min 64 chars) | Générer avec la commande ci-dessous |
| `ALLOWED_ORIGINS` | URLs autorisées CORS | `http://VOTRE_IP,https://votre-domaine.com` |
| `CORS_ORIGIN` | Pareil que ALLOWED_ORIGINS | `http://VOTRE_IP,https://votre-domaine.com` |

> **Générer des secrets JWT forts** :
> ```bash
> node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
> ```
> Exécuter 2 fois pour obtenir `JWT_SECRET` et `JWT_REFRESH_SECRET`.

> **DATABASE_URL** : Si le mot de passe contient `+`, encoder en `%2B` :
> `mysql://<user>:<mot%2Bde%2Bpasse>@<host>:3306/<db_name>`

### 🟡 Variables RECOMMANDÉES

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `JWT_EXPIRES_IN` | Durée de validité du token | `7d` |
| `JWT_REFRESH_EXPIRES_IN` | Durée du refresh token | `30d` |
| `REDIS_ENABLED` | Activer Redis (cache) | `false` (pas de Redis sans Docker) |
| `LOG_LEVEL` | Niveau de logs | `info` |
| `TZ` | Fuseau horaire | `Africa/Abidjan` |
| `MAX_FILE_SIZE` | Taille max upload | `50MB` |
| `UPLOAD_DIR` | Dossier uploads | `uploads` |

### 🔵 Variables OPTIONNELLES (services désactivés)

| Variable | Description | Quand l'activer |
|----------|-------------|-----------------|
| `TWILIO_ACCOUNT_SID` | SID du compte Twilio | Quand Twilio sera souscrit |
| `TWILIO_AUTH_TOKEN` | Token d'auth Twilio | Quand Twilio sera souscrit |
| `TWILIO_PHONE_NUMBER` | Numéro SMS Twilio | Quand Twilio sera souscrit |
| `TWILIO_WHATSAPP_NUMBER` | Numéro WhatsApp Twilio | Quand Twilio sera souscrit |
| `SMTP_HOST` | Serveur SMTP email | Quand emails seront activés |
| `SMTP_PORT` | Port SMTP | `587` (STARTTLS) ou `465` (SSL) |
| `SMTP_USER` | Email expéditeur | Ex: `noreply@agrosmart.ci` |
| `SMTP_PASSWORD` | Mot de passe SMTP | — |
| `REDIS_HOST` | Adresse Redis | `127.0.0.1` si Redis installé |
| `REDIS_PORT` | Port Redis | `6379` |
| `INFLUXDB_URL` | URL InfluxDB | `http://127.0.0.1:8086` |
| `INFLUXDB_TOKEN` | Token InfluxDB | — |
| `OPENWEATHER_API_KEY` | Clé API météo | Depuis openweathermap.org |
| `MQTT_HOST` | Broker MQTT | `127.0.0.1` si Mosquitto installé |
| `IOT_SERVICE_URL` | URL du service IoT | `http://127.0.0.1:4000` |
| `AI_SERVICE_URL` | URL du service IA | `http://127.0.0.1:5001` |

---

## 🌐 Frontend — `frontend/.env.local`

```bash
nano frontend/.env.local
```

| Variable | Description | Valeur |
|----------|-------------|--------|
| `NEXT_PUBLIC_API_URL` | URL de l'API backend (via Nginx) | `http://VOTRE_IP_VPS/api/v1` ou `https://api.votre-domaine.com/api/v1` |
| `NEXT_PUBLIC_SOCKET_URL` | URL WebSocket (Socket.IO) | `http://VOTRE_IP_VPS` ou `https://api.votre-domaine.com` |
| `NODE_ENV` | Mode | `production` |

> ⚠️ **Note importante** : ces variables sont préfixées `NEXT_PUBLIC_` ce qui signifie
> qu'elles sont exposées dans le navigateur. Ne jamais y mettre de secrets.

---

## 📡 IoT Service — `iot_service/.env`

```bash
cp iot_service/.env.example iot_service/.env
nano iot_service/.env
```

| Variable | Description | Valeur |
|----------|-------------|--------|
| `NODE_ENV` | Mode | `production` |
| `PORT` | Port du service IoT | `4000` |
| `MQTT_HOST` | Adresse du broker MQTT | `127.0.0.1` |
| `MQTT_PORT` | Port MQTT | `1883` |
| `MQTT_USERNAME` | Username MQTT (si auth activé) | — |
| `MQTT_PASSWORD` | Password MQTT (si auth activé) | — |
| `REDIS_HOST` | Adresse Redis (requis pour BullMQ) | `127.0.0.1` |
| `REDIS_PORT` | Port Redis | `6379` |
| `BACKEND_API_URL` | URL du backend | `http://127.0.0.1:3600` |
| `IOT_GATEWAY_SECRET` | Secret partagé avec le backend | Chaîne aléatoire sécurisée |

---

## 🤖 AI Service — `ai_service/.env` *(optionnel)*

| Variable | Description | Valeur |
|----------|-------------|--------|
| `FLASK_ENV` | Mode Flask | `production` |
| `FLASK_PORT` | Port du service | `5001` |
| `MODEL_PATH` | Chemin vers les modèles TF | `./models/` |

---

## 📱 Mobile — `mobile/lib/core/config/environment_config.dart`

L'application mobile **ne lit pas de fichier .env**. La configuration est dans le code source.

Pour le déploiement en production, modifier :

```dart
// mobile/lib/core/config/environment_config.dart
static String get apiBaseUrl {
  // Pour Android (emulateur) :
  return 'http://10.0.2.2:3600/api/v1';  // dev local

  // Pour production (à décommenter au moment du build release) :
  // return 'https://api.votre-domaine.com/api/v1';
}
```

> En production, remplacer `10.0.2.2:3600` par `https://api.votre-domaine.com`
> puis rebuild : `flutter build apk --release`

---

## 🔐 Génération des secrets

```bash
# JWT_SECRET (64 bytes = 128 hex chars)
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# JWT_REFRESH_SECRET (64 bytes)
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# IOT_GATEWAY_SECRET (32 bytes)
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

## ✅ Checklist avant déploiement

- [ ] `backend/.env` créé et rempli avec les vraies valeurs
- [ ] `frontend/.env.local` créé avec la bonne IP/domaine dans `NEXT_PUBLIC_API_URL`
- [ ] `ALLOWED_ORIGINS` dans `backend/.env` mis à jour avec l'IP/domaine du VPS
- [ ] `JWT_SECRET` et `JWT_REFRESH_SECRET` générés et robustes (≥ 64 chars)
- [ ] `DATABASE_URL` correctement encodée (caractères spéciaux en `%XX`)
- [ ] Fichiers `.env` **non présents** dans `git status` (vérifier avec `git status --short`)

```bash
# Vérifier que aucun .env n'est tracké par Git
git status --short | grep "\.env"
# Ne doit rien afficher
```
