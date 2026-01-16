#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-ide.ucclab.io}"
EMAIL="${EMAIL:-admin@ucclab.io}"
BASE="/opt/vscode-server"
ENV="${LETSENCRYPT_ENV:-production}"

if [ -d "$BASE/data/nginx/letsencrypt/live/$DOMAIN" ]; then
  echo "Certificate already exists for $DOMAIN"
  exit 0
fi

echo "Bootstrapping TLS certificate for $DOMAIN..."

docker compose -f "$BASE/docker-compose.yml" up -d nginx
sleep 5

STAGING_FLAG=""
if [ "$ENV" = "staging" ]; then
  STAGING_FLAG="--staging"
fi

docker compose -f "$BASE/docker-compose.yml" run --rm certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  $STAGING_FLAG \
  -d "$DOMAIN"

docker compose -f "$BASE/docker-compose.yml" restart nginx
