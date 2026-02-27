#!/bin/sh
set -eu

echo "[EDGE WATCHER ELITE] starting..."

SITES_DIR=/sites
TMP_DIR=/tmp/edge-sites
LOCK_FILE=/tmp/edge-lock
NGINX_CONTAINER=edge-nginx

EDGE_ENABLE_LABEL="edge.enable"
EDGE_DOMAIN_LABEL="edge.domain"
EDGE_PORT_LABEL="edge.port"
EDGE_AUTH_LABEL="edge.auth"

# Optional Authelia integration:
# - create /scripts/auth_domain (mounted from edge gateway host) with value like: auth.example.com
# - label services with: edge.auth=true  (or edge.auth=authelia)
AUTH_DOMAIN_FILE="/scripts/auth_domain"
AUTH_DOMAIN=""
if [ -f "$AUTH_DOMAIN_FILE" ]; then
  AUTH_DOMAIN=$(cat "$AUTH_DOMAIN_FILE" 2>/dev/null | tr -d '\n' || true)
fi

echo "[EDGE WATCHER] waiting for docker socket..."
while [ ! -S /var/run/docker.sock ]; do
  sleep 1
done

echo "[EDGE WATCHER] waiting for nginx container..."
while ! docker inspect "$NGINX_CONTAINER" >/dev/null 2>&1; do
  sleep 1
done

echo "[EDGE WATCHER] waiting for nginx readiness..."
until docker exec "$NGINX_CONTAINER" nginx -t >/dev/null 2>&1; do
  sleep 2
done

echo "[EDGE WATCHER] nginx ready"

generate_configs() {

  if [ -f "$LOCK_FILE" ]; then
    return
  fi
  touch "$LOCK_FILE"

  echo "[EDGE WATCHER] rebuilding configs"

  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"

  FOUND=0

  for id in $(docker ps -q); do

    enable=$(docker inspect -f '{{ index .Config.Labels "'"$EDGE_ENABLE_LABEL"'" }}' "$id" 2>/dev/null || true)
    [ "$enable" = "true" ] || continue

    domain=$(docker inspect -f '{{ index .Config.Labels "'"$EDGE_DOMAIN_LABEL"'" }}' "$id" 2>/dev/null || true)
    port=$(docker inspect -f '{{ index .Config.Labels "'"$EDGE_PORT_LABEL"'" }}' "$id" 2>/dev/null || true)
    auth=$(docker inspect -f '{{ index .Config.Labels "'"$EDGE_AUTH_LABEL"'" }}' "$id" 2>/dev/null || true)
    name=$(docker inspect -f '{{ .Name }}' "$id" 2>/dev/null | sed 's#^/##')

    [ -n "${domain:-}" ] || continue
    [ -n "${port:-}" ] || continue
    [ -n "${name:-}" ] || continue

    FOUND=1

    CERT_PATH="/etc/letsencrypt/live/$domain/fullchain.pem"

    if docker exec "$NGINX_CONTAINER" test -f "$CERT_PATH" >/dev/null 2>&1; then
        SSL_READY=1
    else
        SSL_READY=0
    fi

    AUTH_ENABLED=0
    if [ -n "${AUTH_DOMAIN:-}" ]; then
      if [ "${auth:-}" = "true" ] || [ "${auth:-}" = "authelia" ]; then
        AUTH_ENABLED=1
      fi
    fi

    # ------------------------------------------------------------
    # HTTP BLOCK
    # ------------------------------------------------------------
cat > "$TMP_DIR/$domain.conf" <<EOF
# ------------------------------------------------------------
# HTTP
# ------------------------------------------------------------
server {
    listen 80;
    server_name $domain;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
EOF

    if [ "$SSL_READY" -eq 1 ]; then
cat >> "$TMP_DIR/$domain.conf" <<EOF
        return 301 https://\$host\$request_uri;
EOF
    else
      if [ "$AUTH_ENABLED" -eq 1 ]; then
cat >> "$TMP_DIR/$domain.conf" <<EOF
        auth_request /authelia;
        error_page 401 =302 https://$AUTH_DOMAIN/?rd=\$scheme://\$host\$request_uri;
EOF
      fi

cat >> "$TMP_DIR/$domain.conf" <<EOF
        proxy_pass http://$name:$port;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_read_timeout 3600s;
        proxy_connect_timeout 60s;
EOF
    fi

cat >> "$TMP_DIR/$domain.conf" <<EOF
    }
EOF

    if [ "$AUTH_ENABLED" -eq 1 ]; then
cat >> "$TMP_DIR/$domain.conf" <<EOF

    # Authelia verification endpoint (internal)
    location = /authelia {
        internal;
        proxy_pass http://authelia:9091/api/verify;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URL \$scheme://\$host\$request_uri;
        proxy_set_header X-Forwarded-Method \$request_method;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Uri \$request_uri;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
EOF
    fi

cat >> "$TMP_DIR/$domain.conf" <<EOF
}
EOF

    # ------------------------------------------------------------
    # HTTPS BLOCK (ONLY IF CERT EXISTS)
    # ------------------------------------------------------------
    if [ "$SSL_READY" -eq 1 ]; then
cat >> "$TMP_DIR/$domain.conf" <<EOF

# ------------------------------------------------------------
# HTTPS
# ------------------------------------------------------------
server {
    listen 443 ssl;
    server_name $domain;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    location / {
EOF

      if [ "$AUTH_ENABLED" -eq 1 ]; then
cat >> "$TMP_DIR/$domain.conf" <<EOF
        auth_request /authelia;
        error_page 401 =302 https://$AUTH_DOMAIN/?rd=\$scheme://\$host\$request_uri;
EOF
      fi

cat >> "$TMP_DIR/$domain.conf" <<EOF
        proxy_pass http://$name:$port;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_read_timeout 3600s;
        proxy_connect_timeout 60s;
    }
EOF

      if [ "$AUTH_ENABLED" -eq 1 ]; then
cat >> "$TMP_DIR/$domain.conf" <<EOF

    location = /authelia {
        internal;
        proxy_pass http://authelia:9091/api/verify;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URL \$scheme://\$host\$request_uri;
        proxy_set_header X-Forwarded-Method \$request_method;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Uri \$request_uri;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
EOF
      fi

cat >> "$TMP_DIR/$domain.conf" <<EOF
}
EOF
    fi

  done

  if [ "$FOUND" -eq 0 ]; then
    echo "[EDGE WATCHER] no edge-enabled containers found"
    rm -f "$LOCK_FILE"
    return
  fi

  if ! diff -qr "$TMP_DIR" "$SITES_DIR" >/dev/null 2>&1; then
    echo "[EDGE WATCHER] applying new configs"

    mkdir -p "$SITES_DIR"
    rm -f "$SITES_DIR"/*.conf 2>/dev/null || true
    cp "$TMP_DIR"/*.conf "$SITES_DIR"/
  else
    echo "[EDGE WATCHER] no config changes"
    rm -f "$LOCK_FILE"
    return
  fi

  if docker exec "$NGINX_CONTAINER" nginx -t >/dev/null 2>&1; then
      docker exec "$NGINX_CONTAINER" nginx -s reload >/dev/null 2>&1
      echo "[EDGE WATCHER] nginx reloaded"
  else
      echo "[EDGE WATCHER] config invalid — reload skipped"
  fi

  rm -f "$LOCK_FILE"
}

sleep 3
generate_configs

docker events \
  --filter event=start \
  --filter event=die \
  --filter event=destroy \
  | while read -r _; do
      sleep 2
      generate_configs
done
