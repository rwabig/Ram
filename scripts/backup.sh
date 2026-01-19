#!/usr/bin/env bash
set -euo pipefail
umask 077

# ============================================================
# CONFIGURATION
# ============================================================
BACKUP_DIR="/var/backups/vscode-server"
BASE="/opt/vscode-server"
TS="$(date +%Y%m%d-%H%M%S)"
TMP="$BACKUP_DIR/.vscode-$TS.tmp.tar.gz"
OUT="$BACKUP_DIR/vscode-$TS.tar.gz"
LOG_FILE="$BACKUP_DIR/backup.log"
RETENTION_DAYS=7
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"

# ============================================================
# LOGGING
# ============================================================
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ============================================================
# CLEANUP ON FAILURE
# ============================================================
cleanup() {
  rm -f "$TMP"
}
trap cleanup EXIT

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

if [[ ! -d "$BASE/data" || ! -f "$BASE/docker-compose.yml" ]]; then
  log "❌ Backup source paths missing — aborting"
  exit 1
fi

# Disk space check (require 2× estimated size)
AVAILABLE_KB=$(df -kP "$BACKUP_DIR" | awk 'NR==2 {print $4}')
ESTIMATED_KB=$(du -sk "$BASE" 2>/dev/null | awk '{print $1}' || echo 1048576)

if [[ "$AVAILABLE_KB" -lt $((ESTIMATED_KB * 2)) ]]; then
  log "❌ Insufficient disk space: ${AVAILABLE_KB}KB available, ~${ESTIMATED_KB}KB needed"
  exit 1
fi

# ============================================================
# CREATE BACKUP
# ============================================================
log "📦 Creating backup $OUT..."

if ! GZIP="-$COMPRESSION_LEVEL" tar -czf "$TMP" \
  --warning=no-file-changed \
  --exclude="*.tmp" \
  --exclude="*.log" \
  --exclude="*.pid" \
  "$BASE/data" \
  "$BASE/docker-compose.yml" >>"$LOG_FILE" 2>&1; then

  log "❌ Backup creation failed"
  exit 1
fi

# Verify integrity
if ! tar -tzf "$TMP" >/dev/null 2>&1; then
  log "❌ Backup file is corrupt"
  exit 1
fi

mv -f "$TMP" "$OUT"
chmod 600 "$OUT"

SIZE=$(stat -c%s "$OUT")
log "✅ Backup completed: $OUT (${SIZE} bytes)"

# ============================================================
# PRUNE OLD BACKUPS
# ============================================================
log "🧹 Pruning backups older than $RETENTION_DAYS days..."

mapfile -t OLD < <(find "$BACKUP_DIR" -type f -name "vscode-*.tar.gz" -mtime +"$RETENTION_DAYS" 2>/dev/null || true)

if (( ${#OLD[@]} > 0 )); then
  rm -f -- "${OLD[@]}"
  log "   Removed ${#OLD[@]} old backup(s)"
fi

# ============================================================
# CLEANUP LOGS
# ============================================================
find "$BACKUP_DIR" -type f -name "*.log" -mtime +30 -delete

trap - EXIT
log "🎉 Backup cycle completed successfully"
