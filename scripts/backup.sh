#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/var/backups/vscode-server"
BASE="/opt/vscode-server"
TS=$(date +%Y%m%d)

tar -czf "$BACKUP_DIR/vscode-$TS.tar.gz" \
  "$BASE/data" \
  "$BASE/docker-compose.yml"

find "$BACKUP_DIR" -name "vscode-*.tar.gz" -mtime +7 -delete
