#!/bin/bash
#==============================================================================
# FORT KNOX BACKUP POLICY
# 
# Policy:
#   - 0-7 days:   Stay on Mac Mini (hot storage)
#   - 7-30 days:  Compressed on Mac Pro (Fort Knox)
#   - 30+ days:   Deleted from Fort Knox
#
# Runs daily via launchd
# Location: ~/clawd/scripts/fort-knox-policy.sh
#==============================================================================

set -e

# Configuration
MAC_MINI_BACKUPS="$HOME/backups"
MAC_MINI_VERSIONS="$HOME/clawd-versions"
MAC_PRO="administrator@100.101.89.80"
FORT_KNOX_BACKUPS="~/fort-knox/backups"
FORT_KNOX_VERSIONS="~/fort-knox/clawd-versions"
LOG_FILE="$HOME/clawd/logs/fort-knox.log"
DAYS_TO_KEEP_LOCAL=7
DAYS_TO_KEEP_REMOTE=30

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$(dirname "$LOG_FILE")"

log "=========================================="
log "🏰 FORT KNOX POLICY - Starting"
log "=========================================="

#------------------------------------------------------------------------------
# PHASE 1: Move old backups (7+ days) to Fort Knox
#------------------------------------------------------------------------------
log "Phase 1: Moving 7+ day old backups to Fort Knox..."

# Find and compress old backup files
find "$MAC_MINI_BACKUPS" -name "*.tar.gz" -mtime +$DAYS_TO_KEEP_LOCAL -type f 2>/dev/null | while read file; do
    filename=$(basename "$file")
    log "  Moving: $filename"
    
    # Transfer to Fort Knox
    scp -q "$file" "$MAC_PRO:$FORT_KNOX_BACKUPS/" && rm -f "$file"
    log "  ✓ Transferred and removed local copy"
done

# Find and compress old version folders
find "$MAC_MINI_VERSIONS" -maxdepth 1 -type d -name "v*" -mtime +$DAYS_TO_KEEP_LOCAL 2>/dev/null | while read dir; do
    dirname=$(basename "$dir")
    archive="${dirname}.tar.gz"
    log "  Compressing: $dirname"
    
    # Compress locally first
    tar -czf "/tmp/$archive" -C "$MAC_MINI_VERSIONS" "$dirname" 2>/dev/null
    
    # Transfer to Fort Knox
    scp -q "/tmp/$archive" "$MAC_PRO:$FORT_KNOX_VERSIONS/" && rm -rf "$dir" "/tmp/$archive"
    log "  ✓ Compressed, transferred, cleaned up"
done

#------------------------------------------------------------------------------
# PHASE 2: Delete old backups from Fort Knox (30+ days)
#------------------------------------------------------------------------------
log "Phase 2: Cleaning Fort Knox (30+ day old files)..."

# Delete old files from Fort Knox
ssh "$MAC_PRO" "find $FORT_KNOX_BACKUPS -name '*.tar.gz' -mtime +$DAYS_TO_KEEP_REMOTE -delete -print 2>/dev/null" | while read file; do
    log "  🗑️ Deleted: $(basename $file)"
done

ssh "$MAC_PRO" "find $FORT_KNOX_VERSIONS -name '*.tar.gz' -mtime +$DAYS_TO_KEEP_REMOTE -delete -print 2>/dev/null" | while read file; do
    log "  🗑️ Deleted: $(basename $file)"
done

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
log "=========================================="
log "Summary:"
log "  Mac Mini backups: $(ls $MAC_MINI_BACKUPS/*.tar.gz 2>/dev/null | wc -l | tr -d ' ') files"
log "  Mac Mini versions: $(ls -d $MAC_MINI_VERSIONS/v*/ 2>/dev/null | wc -l | tr -d ' ') folders"
log "  Fort Knox backups: $(ssh $MAC_PRO "ls $FORT_KNOX_BACKUPS/*.tar.gz 2>/dev/null | wc -l" | tr -d ' ') files"
log "  Fort Knox versions: $(ssh $MAC_PRO "ls $FORT_KNOX_VERSIONS/*.tar.gz 2>/dev/null | wc -l" | tr -d ' ') files"
log "  Mac Mini disk: $(df -h / | tail -1 | awk '{print $5, "(" $4 " free)"}')"
log "=========================================="
log "🏰 FORT KNOX POLICY - Complete"
