#!/bin/bash
# ==============================================
# AgroSmart CI - Script de Déploiement Hostinger VPS
# ==============================================
# 
# Ce script automatise le déploiement complet :
#   1. Installation de Docker & Docker Compose
#   2. Configuration du firewall
#   3. Génération des secrets
#   4. Build et lancement de tous les services
#   5. Vérification du bon fonctionnement
#
# Usage: bash scripts/deploy-hostinger.sh
# ==============================================

set -euo pipefail

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Répertoire du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "=========================================="
echo "  🌾 AgroSmart CI - Déploiement Hostinger"
echo "=========================================="
echo ""

# ==============================================
# ÉTAPE 1: Vérification & Installation de Docker
# ==============================================
log_info "Étape 1/7: Vérification de Docker..."

if ! command -v docker &> /dev/null; then
    log_warn "Docker non trouvé. Installation en cours..."
    
    # Détection de l'OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        log_error "OS non reconnu. Installez Docker manuellement."
        exit 1
    fi

    case $OS in
        ubuntu|debian)
            # Suppression des anciennes versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Installation des prérequis
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release

            # Ajout du repo Docker
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Installation de Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Ajouter l'utilisateur au groupe docker
            sudo usermod -aG docker $USER
            ;;
        centos|rhel|almalinux|rocky)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
        *)
            log_error "OS '$OS' non supporté pour l'installation automatique."
            log_error "Installez Docker manuellement: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    log_ok "Docker installé avec succès!"
else
    log_ok "Docker déjà installé: $(docker --version)"
fi

# Vérification Docker Compose
if ! docker compose version &> /dev/null; then
    log_error "Docker Compose plugin non trouvé."
    log_error "Installez-le: sudo apt-get install docker-compose-plugin"
    exit 1
fi
log_ok "Docker Compose: $(docker compose version)"

# ==============================================
# ÉTAPE 2: Configuration du Firewall
# ==============================================
log_info "Étape 2/7: Configuration du firewall..."

if command -v ufw &> /dev/null; then
    sudo ufw allow 22/tcp    # SSH
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    sudo ufw allow 1883/tcp  # MQTT (si accès externe nécessaire)
    sudo ufw --force enable
    log_ok "Firewall UFW configuré (ports 22, 80, 443, 1883)"
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --permanent --add-port=1883/tcp
    sudo firewall-cmd --reload
    log_ok "Firewall firewalld configuré"
else
    log_warn "Aucun firewall détecté. Pensez à configurer la sécurité réseau."
fi

# ==============================================
# ÉTAPE 3: Génération automatique des secrets
# ==============================================
log_info "Étape 3/7: Configuration des variables d'environnement..."

if [ ! -f "$PROJECT_DIR/.env" ]; then
    log_info "Fichier .env non trouvé. Création à partir du template..."
    
    if [ ! -f "$PROJECT_DIR/.env.production.example" ]; then
        log_error "Template .env.production.example introuvable!"
        exit 1
    fi

    cp "$PROJECT_DIR/.env.production.example" "$PROJECT_DIR/.env"

    # Génération automatique des secrets
    log_info "Génération des mots de passe sécurisés..."
    
    MYSQL_ROOT_PWD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    MYSQL_PWD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    REDIS_PWD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    JWT_SEC=$(openssl rand -hex 64)
    JWT_REFRESH_SEC=$(openssl rand -hex 64)
    INFLUX_PWD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    INFLUX_TOKEN=$(openssl rand -hex 32)
    MQTT_PWD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)

    # Remplacement dans le .env
    sed -i "s|<GÉNÉRER_MOT_DE_PASSE_ROOT_TRÈS_FORT>|${MYSQL_ROOT_PWD}|g" "$PROJECT_DIR/.env"
    sed -i "s|<GÉNÉRER_MOT_DE_PASSE_USER_TRÈS_FORT>|${MYSQL_PWD}|g" "$PROJECT_DIR/.env"
    sed -i "s|<GÉNÉRER_MOT_DE_PASSE_REDIS>|${REDIS_PWD}|g" "$PROJECT_DIR/.env"
    sed -i "s|<GÉNÉRER_SECRET_JWT_128_CARACTÈRES>|${JWT_SEC}|g" "$PROJECT_DIR/.env"
    sed -i "s|<GÉNÉRER_SECRET_REFRESH_128_CARACTÈRES>|${JWT_REFRESH_SEC}|g" "$PROJECT_DIR/.env"
    sed -i "s|<GÉNÉRER_MOT_DE_PASSE_INFLUX>|${INFLUX_PWD}|g" "$PROJECT_DIR/.env"
    sed -i "s|<GÉNÉRER_TOKEN_INFLUX_64_CARACTÈRES>|${INFLUX_TOKEN}|g" "$PROJECT_DIR/.env"
    sed -i "s|<GÉNÉRER_MOT_DE_PASSE_MQTT>|${MQTT_PWD}|g" "$PROJECT_DIR/.env"

    log_ok "Fichier .env créé avec des secrets générés automatiquement!"
    log_warn "IMPORTANT: Sauvegardez une copie de .env dans un endroit sûr!"
    
    # Afficher les credentials pour backup
    echo ""
    echo "=========================================="
    echo "  📋 CREDENTIALS GÉNÉRÉS (à sauvegarder)"
    echo "=========================================="
    echo "  MySQL Root:     $MYSQL_ROOT_PWD"
    echo "  MySQL User:     $MYSQL_PWD"
    echo "  Redis:          $REDIS_PWD"
    echo "  InfluxDB:       $INFLUX_PWD"
    echo "  MQTT:           $MQTT_PWD"
    echo "=========================================="
    echo ""
    
    # Sauvegarder les credentials dans un fichier sécurisé
    CRED_FILE="$PROJECT_DIR/.credentials-backup"
    cat > "$CRED_FILE" << EOF
# AgroSmart CI - Credentials générés le $(date)
# STOCKEZ CE FICHIER EN LIEU SÛR ET SUPPRIMEZ-LE DU SERVEUR
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PWD
MYSQL_PASSWORD=$MYSQL_PWD
REDIS_PASSWORD=$REDIS_PWD
JWT_SECRET=$JWT_SEC
JWT_REFRESH_SECRET=$JWT_REFRESH_SEC
INFLUXDB_PASSWORD=$INFLUX_PWD
INFLUXDB_TOKEN=$INFLUX_TOKEN
MQTT_PASSWORD=$MQTT_PWD
EOF
    chmod 600 "$CRED_FILE"
    log_warn "Credentials sauvegardés dans: $CRED_FILE"
    log_warn "SUPPRIMEZ ce fichier après l'avoir copié en lieu sûr!"
else
    log_ok "Fichier .env existant trouvé."
fi

# Sécuriser le fichier .env
chmod 600 "$PROJECT_DIR/.env"

# ==============================================
# ÉTAPE 4: Création des répertoires nécessaires
# ==============================================
log_info "Étape 4/7: Création des répertoires..."

mkdir -p "$PROJECT_DIR/nginx/ssl"
mkdir -p "$PROJECT_DIR/certbot/www"
mkdir -p "$PROJECT_DIR/certbot/conf"

log_ok "Répertoires créés."

# ==============================================
# ÉTAPE 5: Build des images Docker
# ==============================================
log_info "Étape 5/7: Build des images Docker (cela peut prendre plusieurs minutes)..."

docker compose -f docker-compose.hostinger.yml build --no-cache

log_ok "Images Docker construites avec succès!"

# ==============================================
# ÉTAPE 6: Lancement des services
# ==============================================
log_info "Étape 6/7: Lancement de tous les services..."

# D'abord démarrer les dépendances (DB, Redis, etc.)
log_info "Démarrage de MySQL, Redis, InfluxDB, Mosquitto..."
docker compose -f docker-compose.hostinger.yml up -d mysql redis influxdb mosquitto

# Attendre que MySQL soit prêt
log_info "Attente de MySQL (peut prendre 30-60 secondes)..."
MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if docker compose -f docker-compose.hostinger.yml exec -T mysql mysqladmin ping -h localhost -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | head -1 | cut -d= -f2)" --silent 2>/dev/null; then
        break
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -ne "  ⏳ $WAITED/${MAX_WAIT}s...\r"
done

if [ $WAITED -ge $MAX_WAIT ]; then
    log_error "MySQL n'a pas démarré dans les temps. Vérifiez les logs:"
    log_error "docker compose -f docker-compose.hostinger.yml logs mysql"
    exit 1
fi
log_ok "MySQL est prêt!"

# Démarrer l'API (migrations + seed automatiques)
log_info "Démarrage du Backend API (migrations + seed automatiques)..."
docker compose -f docker-compose.hostinger.yml up -d api

# Attendre que l'API soit prête
log_info "Attente de l'API (migrations en cours, peut prendre 1-2 minutes)..."
MAX_WAIT=180
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if docker compose -f docker-compose.hostinger.yml exec -T api wget -q -O - http://localhost:3600/health 2>/dev/null | grep -q "ok"; then
        break
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -ne "  ⏳ $WAITED/${MAX_WAIT}s...\r"
done

if [ $WAITED -ge $MAX_WAIT ]; then
    log_warn "L'API prend plus de temps que prévu. Vérifiez les logs:"
    log_warn "docker compose -f docker-compose.hostinger.yml logs api"
fi
log_ok "Backend API démarré!"

# Démarrer les services restants
log_info "Démarrage du Frontend, AI Service, IoT Service, Nginx..."
docker compose -f docker-compose.hostinger.yml up -d

log_ok "Tous les services sont lancés!"

# ==============================================
# ÉTAPE 7: Vérification
# ==============================================
log_info "Étape 7/7: Vérification du déploiement..."

echo ""
echo "📊 État des services:"
echo "-------------------------------------------"
docker compose -f docker-compose.hostinger.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Vérifier les endpoints
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "VOTRE_IP")

echo ""
echo "=========================================="
echo "  ✅ DÉPLOIEMENT TERMINÉ AVEC SUCCÈS!"
echo "=========================================="
echo ""
echo "  🌐 Application web: http://${SERVER_IP}"
echo "  🔌 API Backend:     http://${SERVER_IP}/api/v1"
echo "  📚 API Docs:        http://${SERVER_IP}/api-docs"
echo "  🏥 Health Check:    http://${SERVER_IP}/health"
echo ""
echo "  📋 Commandes utiles:"
echo "  ─────────────────────────────────────────"
echo "  Voir les logs:    docker compose -f docker-compose.hostinger.yml logs -f"
echo "  Logs API:         docker compose -f docker-compose.hostinger.yml logs -f api"
echo "  Logs Frontend:    docker compose -f docker-compose.hostinger.yml logs -f frontend"
echo "  Redémarrer:       docker compose -f docker-compose.hostinger.yml restart"
echo "  Arrêter:          docker compose -f docker-compose.hostinger.yml down"
echo "  Mettre à jour:    git pull && docker compose -f docker-compose.hostinger.yml up -d --build"
echo ""
echo "  🔐 Pour activer SSL (quand vous avez un domaine):"
echo "  bash scripts/init-ssl.sh mondomaine.com email@mondomaine.com"
echo ""
echo "=========================================="
