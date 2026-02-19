#!/bin/bash
# ==============================================
# AgroSmart CI - Initialisation SSL Let's Encrypt
# ==============================================
# 
# Usage: bash scripts/init-ssl.sh <DOMAINE> <EMAIL>
# Exemple: bash scripts/init-ssl.sh mondomaine.com admin@mondomaine.com
#
# Prérequis:
#   - Le domaine doit pointer vers l'IP du serveur (DNS A record)
#   - Les services doivent être lancés (deploy-hostinger.sh)
#   - Le port 80 doit être accessible depuis Internet
# ==============================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Vérification des arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <DOMAINE> <EMAIL>"
    echo "Exemple: $0 mondomaine.com admin@mondomaine.com"
    exit 1
fi

DOMAIN="$1"
EMAIL="$2"

echo ""
echo "=========================================="
echo "  🔐 AgroSmart CI - Configuration SSL"
echo "=========================================="
echo "  Domaine: $DOMAIN"
echo "  Email:   $EMAIL"
echo "=========================================="
echo ""

# ==============================================
# Étape 1: Vérification DNS
# ==============================================
log_info "Vérification que $DOMAIN pointe vers ce serveur..."

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "")
DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null || host "$DOMAIN" 2>/dev/null | awk '/has address/ {print $4}' || echo "")

if [ -z "$DOMAIN_IP" ]; then
    log_error "Impossible de résoudre $DOMAIN. Vérifiez votre configuration DNS."
    log_error "Ajoutez un enregistrement A: $DOMAIN → $SERVER_IP"
    exit 1
fi

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    log_warn "Le domaine $DOMAIN pointe vers $DOMAIN_IP"
    log_warn "L'IP de ce serveur est $SERVER_IP"
    log_warn "Si vous utilisez un proxy (Cloudflare), c'est normal."
    read -p "Continuer quand même ? (y/N) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    log_ok "DNS OK: $DOMAIN → $SERVER_IP"
fi

# ==============================================
# Étape 2: Obtention du certificat
# ==============================================
log_info "Obtention du certificat SSL via Let's Encrypt..."

# S'assurer que nginx est lancé pour le challenge HTTP
docker compose -f docker-compose.hostinger.yml up -d nginx

sleep 5

# Lancer certbot pour obtenir le certificat
docker compose -f docker-compose.hostinger.yml run --rm certbot \
    certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN" \
    -d "www.$DOMAIN"

if [ $? -ne 0 ]; then
    log_error "Échec de l'obtention du certificat SSL."
    log_error "Vérifiez que le port 80 est accessible et que le DNS est correct."
    exit 1
fi

log_ok "Certificat SSL obtenu pour $DOMAIN!"

# ==============================================
# Étape 3: Mise à jour de la config Nginx
# ==============================================
log_info "Mise à jour de la configuration Nginx pour HTTPS..."

# Créer la config Nginx avec SSL
cat > "$PROJECT_DIR/nginx/hostinger.conf" << 'NGINX_CONF'
worker_processes auto;
worker_rlimit_nofile 65535;

error_log /var/log/nginx/error.log warn;
pid       /tmp/nginx.pid;

events {
    worker_connections 2048;
    multi_accept on;
    use epoll;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    '$request_time $upstream_response_time';

    access_log /var/log/nginx/access.log main;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 50M;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml application/xml+rss application/x-javascript image/svg+xml;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

    upstream backend_api {
        server api:3600;
        keepalive 32;
    }

    upstream frontend_app {
        server frontend:3601;
        keepalive 16;
    }

    # HTTP → HTTPS redirect
    server {
        listen 80;
        listen [::]:80;
NGINX_CONF

echo "        server_name $DOMAIN www.$DOMAIN;" >> "$PROJECT_DIR/nginx/hostinger.conf"

cat >> "$PROJECT_DIR/nginx/hostinger.conf" << 'NGINX_CONF'

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
NGINX_CONF

echo "        server_name $DOMAIN www.$DOMAIN;" >> "$PROJECT_DIR/nginx/hostinger.conf"
echo "" >> "$PROJECT_DIR/nginx/hostinger.conf"
echo "        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;" >> "$PROJECT_DIR/nginx/hostinger.conf"
echo "        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;" >> "$PROJECT_DIR/nginx/hostinger.conf"

cat >> "$PROJECT_DIR/nginx/hostinger.conf" << 'NGINX_CONF'

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        location /api/ {
            limit_req zone=api burst=50 nodelay;
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 30s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            proxy_buffering off;
        }

        location /api/v1/auth/ {
            limit_req zone=auth burst=10 nodelay;
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /socket.io/ {
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
        }

        location /api-docs { proxy_pass http://backend_api; proxy_set_header Host $host; }
        location /uploads/ { proxy_pass http://backend_api; expires 30d; add_header Cache-Control "public, immutable"; }
        location /health { proxy_pass http://backend_api; access_log off; }
        location /_next/static/ { proxy_pass http://frontend_app; expires 365d; add_header Cache-Control "public, immutable"; access_log off; }
        location /_next/image { proxy_pass http://frontend_app; proxy_set_header Host $host; }

        location / {
            proxy_pass http://frontend_app;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
NGINX_CONF

log_ok "Configuration Nginx HTTPS générée!"

# ==============================================
# Étape 4: Mise à jour du .env
# ==============================================
log_info "Mise à jour des URLs dans .env..."

sed -i "s|^NEXT_PUBLIC_API_URL=.*|NEXT_PUBLIC_API_URL=https://$DOMAIN/api/v1|" "$PROJECT_DIR/.env"
sed -i "s|^NEXT_PUBLIC_SOCKET_URL=.*|NEXT_PUBLIC_SOCKET_URL=https://$DOMAIN|" "$PROJECT_DIR/.env"
sed -i "s|^CORS_ORIGIN=.*|CORS_ORIGIN=https://$DOMAIN,https://www.$DOMAIN|" "$PROJECT_DIR/.env"
sed -i "s|^ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN|" "$PROJECT_DIR/.env"
sed -i "s|^DOMAIN_NAME=.*|DOMAIN_NAME=$DOMAIN|" "$PROJECT_DIR/.env"
sed -i "s|^CERTBOT_EMAIL=.*|CERTBOT_EMAIL=$EMAIL|" "$PROJECT_DIR/.env"

log_ok ".env mis à jour avec le domaine $DOMAIN"

# ==============================================
# Étape 5: Reconstruire le frontend et recharger
# ==============================================
log_info "Reconstruction du frontend avec les nouvelles URLs..."

docker compose -f docker-compose.hostinger.yml up -d --build frontend

log_info "Rechargement de Nginx..."
docker compose -f docker-compose.hostinger.yml restart nginx

# ==============================================
# Étape 6: Configuration du renouvellement automatique
# ==============================================
log_info "Configuration du renouvellement automatique SSL..."

# Créer le cron job pour le renouvellement
CRON_JOB="0 3 * * * cd $PROJECT_DIR && docker compose -f docker-compose.hostinger.yml run --rm certbot renew --quiet && docker compose -f docker-compose.hostinger.yml exec nginx nginx -s reload"

# Vérifier si le cron existe déjà
if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    log_ok "Cron de renouvellement SSL configuré (tous les jours à 3h)"
else
    log_ok "Cron de renouvellement SSL déjà configuré"
fi

echo ""
echo "=========================================="
echo "  ✅ SSL CONFIGURÉ AVEC SUCCÈS!"
echo "=========================================="
echo ""
echo "  🌐 https://$DOMAIN"
echo "  🌐 https://www.$DOMAIN"
echo "  🔌 https://$DOMAIN/api/v1"
echo "  📚 https://$DOMAIN/api-docs"
echo ""
echo "  Le certificat sera renouvelé automatiquement."
echo "=========================================="
