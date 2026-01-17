#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================
DOMAIN="${DOMAIN:-ide.ucclab.io}"
EMAIL="${EMAIL:-admin@ucclab.io}"
BASE="${BASE:-/opt/vscode-server}"
ENVIRONMENT="${LETSENCRYPT_ENV:-production}"   # "staging" or "production"

COMPOSE="docker compose -f $BASE/docker-compose.yml"
LIVE_DIR="$BASE/data/nginx/letsencrypt/live/$DOMAIN"

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================
if [[ ! -f "$BASE/docker-compose.yml" ]]; then
  echo "❌ docker-compose.yml not found at $BASE"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed"
  exit 1
fi

# ============================================================
# EXIT IF CERT ALREADY EXISTS
# ============================================================
if [[ -d "$LIVE_DIR" ]]; then
  echo "✅ Certificate already exists for $DOMAIN — skipping bootstrap"
  exit 0
fi

# ============================================================
# PREPARE CERTBOT FLAGS
# ============================================================
STAGING_FLAG=""
if [[ "$ENVIRONMENT" == "staging" ]]; then
  echo "⚠️  Using Let's Encrypt STAGING environment"
  STAGING_FLAG="--staging"
fi

# ============================================================
# START NGINX FOR ACME CHALLENGE
# ============================================================
echo "🚀 Starting nginx for ACME challenge..."
$COMPOSE up -d nginx

# Wait until nginx is reachable
echo "⏳ Waiting for nginx to become ready..."
for i in {1..10}; do
  if curl -fsS "http://127.0.0.1/.well-known/acme-challenge/" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# ============================================================
# REQUEST CERTIFICATE
# ============================================================
echo "🔐 Requesting TLS certificate for $DOMAIN..."
$COMPOSE run --rm certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  $STAGING_FLAG \
  -d "$DOMAIN"

# ============================================================
# VERIFY CERTIFICATE
# ============================================================
if [[ ! -f "$LIVE_DIR/fullchain.pem" ]]; then
  echo "❌ Certificate issuance failed — file not found"
  exit 1
fi

# ============================================================
# RELOAD NGINX
# ============================================================
echo "🔄 Reloading nginx..."
$COMPOSE restart nginx

echo "🎉 TLS bootstrap complete for $DOMAIN"
