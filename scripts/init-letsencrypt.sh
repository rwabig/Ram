#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================
DOMAIN="${DOMAIN:-ide.ucclab.io}"
EMAIL="${EMAIL:-admin@ucclab.io}"
BASE="${BASE:-/opt/vscode-server}"
ENVIRONMENT="${LETSENCRYPT_ENV:-production}"   # staging | production

COMPOSE="docker compose"
LIVE_DIR="$BASE/data/nginx/letsencrypt/live/$DOMAIN"

# ============================================================
# PREFLIGHT
# ============================================================
command -v docker >/dev/null || { echo "❌ Docker not installed"; exit 1; }
[[ -f "$BASE/docker-compose.yml" ]] || { echo "❌ docker-compose.yml not found"; exit 1; }

# ============================================================
# EXIT IF CERT EXISTS
# ============================================================
if [[ -f "$LIVE_DIR/fullchain.pem" ]]; then
  echo "✅ Certificate already exists for $DOMAIN — skipping bootstrap"
  exit 0
fi

# ============================================================
# CERTBOT FLAGS
# ============================================================
STAGING_FLAG=""
if [[ "$ENVIRONMENT" == "staging" ]]; then
  echo "⚠️  Using Let's Encrypt STAGING environment"
  STAGING_FLAG="--staging"
else
  echo "⚠️  PRODUCTION: Let's Encrypt rate limits apply"
  echo "   - Certificates per domain: 50/week"
  echo "   - Duplicate certificates: 5/week"
  echo "   - Failed validations: 5/hour"
fi

# ============================================================
# ENSURE CERTBOT DIRECTORIES EXIST
# ============================================================
echo "📁 Creating required directories..."
mkdir -p "$BASE/data/nginx/letsencrypt" "$BASE/data/nginx/certbot"

# ============================================================
# START NGINX (HTTP ONLY)
# ============================================================
echo "🚀 Starting nginx for ACME challenge..."
cd "$BASE"
$COMPOSE up -d nginx

# ============================================================
# WAIT FOR NGINX TO BIND PORT 80
# ============================================================
echo "⏳ Waiting for nginx to bind port 80..."
for i in {1..30}; do
  if $COMPOSE ps nginx | grep -q "Up" && \
     curl -fsS http://localhost >/dev/null 2>&1; then
    echo "✅ nginx is ready"
    break
  fi
  sleep 2
  echo "Still waiting for nginx... ($i/30)"
  if [[ "$i" == "30" ]]; then
    echo "❌ nginx did not become ready — aborting"
    $COMPOSE logs nginx --tail=20
    exit 1
  fi
done

# ============================================================
# REQUEST CERTIFICATE
# ============================================================
echo "🔐 Requesting TLS certificate for $DOMAIN..."
if $COMPOSE run --rm certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  $STAGING_FLAG \
  -d "$DOMAIN"; then
  echo "✅ Certificate issued successfully"
else
  echo "❌ Certificate issuance failed"
  echo "⚠️  Check domain DNS settings and ensure port 80 is accessible"
  exit 1
fi

# ============================================================
# VERIFY CERTIFICATE
# ============================================================
if [[ ! -f "$LIVE_DIR/fullchain.pem" ]]; then
  echo "❌ Certificate file not found at $LIVE_DIR/fullchain.pem"
  exit 1
fi

# ============================================================
# RESTART NGINX WITH SSL
# ============================================================
echo "🔄 Restarting nginx with SSL configuration..."
$COMPOSE restart nginx

# ============================================================
# VERIFY HTTPS
# ============================================================
echo "🔍 Verifying HTTPS is working..."
sleep 5
if curl -kfsS https://localhost >/dev/null 2>&1 || \
   curl -fsS https://localhost >/dev/null 2>&1; then
  echo "✅ HTTPS is working correctly"
else
  echo "⚠️  HTTPS verification failed (but certificate was issued)"
  echo "   Nginx might need additional configuration"
fi

echo "🎉 TLS bootstrap complete for $DOMAIN"
