# 🌾 AgroSmart CI - Guide de Déploiement Hostinger VPS

## Architecture de déploiement

```
Internet
    │
    ▼
┌──────────────────┐
│  Nginx (port 80)  │ ← Reverse Proxy + SSL
│  (port 443)       │
└────────┬─────────┘
         │
    ┌────┴────────────────────────────┐
    │                                  │
    ▼                                  ▼
┌──────────┐                    ┌──────────────┐
│ Frontend │ (port 3001)        │  Backend API │ (port 3000)
│ Next.js  │                    │  Node.js     │
└──────────┘                    └──────┬───────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                    │
                    ▼                  ▼                    ▼
             ┌──────────┐      ┌──────────┐         ┌──────────┐
             │  MySQL   │      │  Redis   │         │ AI Svc   │
             │  (3306)  │      │  (6379)  │         │ (5001)   │
             └──────────┘      └──────────┘         └──────────┘
                    │
                    ├── InfluxDB (8086)
                    ├── Mosquitto MQTT (1883)
                    └── IoT Service (4000)
```

## Prérequis

- **VPS Hostinger** : KVM 4 (4 vCPU, 16GB RAM) recommandé
- **OS** : Ubuntu 22.04/24.04 LTS ou Debian 12
- **Accès** : SSH root ou utilisateur sudo
- **Domaine** : Optionnel au début (accès par IP possible)

## 🚀 Déploiement en une commande

### 1. Se connecter au VPS

```bash
ssh root@VOTRE_IP_VPS
```

### 2. Cloner le projet

```bash
cd /opt
git clone https://github.com/davis48/agrosmart.git
cd agrosmart
```

### 3. Lancer le déploiement

```bash
bash scripts/deploy-hostinger.sh
```

**C'est tout !** Le script automatise :
- ✅ Installation de Docker & Docker Compose
- ✅ Configuration du firewall (ports 80, 443, 22)
- ✅ Génération de tous les mots de passe sécurisés
- ✅ Build de toutes les images Docker
- ✅ Démarrage de MySQL, Redis, InfluxDB, Mosquitto
- ✅ **Création automatique de toutes les tables** (Prisma migrate)
- ✅ **Insertion des données initiales** (régions, cultures, admin, etc.)
- ✅ Démarrage du backend, frontend, services IA et IoT
- ✅ Configuration de Nginx en reverse proxy

## Vérification après déploiement

| Service | URL | Attendu |
|---------|-----|---------|
| Application Web | `http://VOTRE_IP` | Page d'accueil Next.js |
| API Backend | `http://VOTRE_IP/api/v1/health` | `{"status":"ok"}` |
| Documentation API | `http://VOTRE_IP/api-docs` | Swagger UI |
| Health Check | `http://VOTRE_IP/health` | `{"status":"ok"}` |

## 🔐 Activer SSL (quand vous avez un domaine)

### 1. Configurer le DNS

Ajoutez un enregistrement **A** chez votre registrar :
```
mondomaine.com     → VOTRE_IP_VPS
www.mondomaine.com → VOTRE_IP_VPS
```

### 2. Lancer la configuration SSL

```bash
bash scripts/init-ssl.sh mondomaine.com email@mondomaine.com
```

Le script :
- Vérifie le DNS
- Obtient un certificat Let's Encrypt gratuit
- Configure Nginx pour HTTPS
- Active la redirection HTTP → HTTPS
- Configure le renouvellement automatique du certificat

## 📋 Commandes utiles

### Gestion des services

```bash
# Voir l'état de tous les services
docker compose -f docker-compose.hostinger.yml ps

# Voir les logs en temps réel
docker compose -f docker-compose.hostinger.yml logs -f

# Logs d'un service spécifique
docker compose -f docker-compose.hostinger.yml logs -f api
docker compose -f docker-compose.hostinger.yml logs -f frontend
docker compose -f docker-compose.hostinger.yml logs -f mysql

# Redémarrer un service
docker compose -f docker-compose.hostinger.yml restart api

# Arrêter tout
docker compose -f docker-compose.hostinger.yml down

# Arrêter et supprimer les volumes (⚠️ PERD LES DONNÉES)
docker compose -f docker-compose.hostinger.yml down -v
```

### Mise à jour de l'application

```bash
cd /opt/agrosmart
git pull origin main
docker compose -f docker-compose.hostinger.yml up -d --build
```

### Base de données

```bash
# Accéder à MySQL en CLI
docker compose -f docker-compose.hostinger.yml exec mysql mysql -u agrismart -p agrismart_ci

# Relancer les migrations manuellement
docker compose -f docker-compose.hostinger.yml exec api npx prisma migrate deploy

# Relancer le seed manuellement
docker compose -f docker-compose.hostinger.yml exec api node scripts/seed-complete.js

# Backup de la base de données
docker compose -f docker-compose.hostinger.yml exec mysql \
  mysqldump -u root -p$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2) agrismart_ci > backup_$(date +%Y%m%d).sql

# Restaurer un backup
docker compose -f docker-compose.hostinger.yml exec -T mysql \
  mysql -u root -p$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2) agrismart_ci < backup.sql
```

### Monitoring

```bash
# Utilisation des ressources
docker stats

# Espace disque des volumes
docker system df

# Nettoyer les images Docker inutilisées
docker system prune -a --volumes
```

## 🔧 Dépannage

### L'API ne démarre pas

```bash
# Vérifier les logs
docker compose -f docker-compose.hostinger.yml logs api

# Vérifier que MySQL est accessible
docker compose -f docker-compose.hostinger.yml exec api node -e "
  const mysql = require('mysql2/promise');
  mysql.createConnection(process.env.DATABASE_URL)
    .then(c => { console.log('OK'); c.end(); })
    .catch(e => console.error(e.message));
"
```

### Le frontend affiche une erreur

```bash
# Vérifier le build
docker compose -f docker-compose.hostinger.yml logs frontend

# Reconstruire le frontend
docker compose -f docker-compose.hostinger.yml up -d --build frontend
```

### MySQL prend trop de mémoire

Modifiez dans `docker-compose.hostinger.yml` :
```yaml
deploy:
  resources:
    limits:
      memory: 2G  # Réduire si nécessaire
```

### Erreur "port already in use"

```bash
# Trouver le processus qui utilise le port
sudo lsof -i :80
sudo lsof -i :443

# Si c'est Apache (souvent pré-installé sur Hostinger)
sudo systemctl stop apache2
sudo systemctl disable apache2
```

## 📁 Fichiers de déploiement

| Fichier | Description |
|---------|-------------|
| `docker-compose.hostinger.yml` | Compose principal (tous les services) |
| `backend/Dockerfile.prod` | Image production du backend |
| `backend/entrypoint.prod.sh` | Script d'entrée (migrations + seed + start) |
| `frontend/Dockerfile.prod` | Image production du frontend |
| `nginx/hostinger.conf` | Config Nginx reverse proxy |
| `.env.production.example` | Template des variables d'environnement |
| `scripts/deploy-hostinger.sh` | Script de déploiement automatique |
| `scripts/init-ssl.sh` | Script de configuration SSL |

## 🔄 Backup automatique (recommandé)

Créer un script de backup quotidien :

```bash
# Créer le script
cat > /opt/agrosmart/scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/agrosmart"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M)

cd /opt/agrosmart

# Backup MySQL
docker compose -f docker-compose.hostinger.yml exec -T mysql \
  mysqldump -u root -p$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2) \
  --all-databases --single-transaction > $BACKUP_DIR/mysql_$DATE.sql

# Backup uploads
tar czf $BACKUP_DIR/uploads_$DATE.tar.gz -C /var/lib/docker/volumes agrismart_prod_uploads

# Garder seulement les 7 derniers backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup terminé: $DATE"
EOF

chmod +x /opt/agrosmart/scripts/backup.sh

# Ajouter au cron (tous les jours à 2h du matin)
echo "0 2 * * * /opt/agrosmart/scripts/backup.sh >> /var/log/agrosmart-backup.log 2>&1" | crontab -
```

## ⚠️ Sécurité

- Les mots de passe sont générés automatiquement par le script de déploiement
- Le fichier `.credentials-backup` contient les credentials générés → **le copier en lieu sûr puis le supprimer**
- Seuls les ports 80 (HTTP), 443 (HTTPS), et 22 (SSH) sont exposés
- MySQL, Redis, InfluxDB ne sont **pas accessibles depuis l'extérieur**
- Le backend tourne sous un utilisateur non-root dans Docker
- Les headers de sécurité (HSTS, X-Frame-Options, etc.) sont configurés dans Nginx
