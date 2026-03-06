#!/bin/bash
# Unified Backup Strategy
# Usage: unified-backup.sh [incremental|daily|weekly|monthly]

set -e

BACKUP_ROOT="$HOME/backups"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TYPE=${1:-daily}

# Retention policies
INCREMENTAL_KEEP=4      # 24 hours (6hr intervals)
DAILY_KEEP=7            # 7 days
WEEKLY_KEEP=4           # 4 weeks
MONTHLY_KEEP=2          # 2 months

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Backup Mac Mini local data
backup_mac_mini() {
    local dest="$BACKUP_ROOT/mac-mini/$TYPE"
    mkdir -p "$dest"
    
    log "Backing up Mac Mini clawd workspace..."
    tar -czf "$dest/clawd_$TIMESTAMP.tar.gz" \
        -C $HOME \
        --exclude='clawd/.git' \
        --exclude='clawd/node_modules' \
        clawd/ 2>/dev/null || true
    
    log "Backing up dashboard specifically..."
    tar -czf "$dest/dashboard_$TIMESTAMP.tar.gz" \
        -C $HOME/clawd \
        dashboard/ 2>/dev/null || true
        
    log "Mac Mini backup complete: $dest"
}

# Backup Dell via SSH (Windows - uses PowerShell)
backup_dell() {
    local dest="$BACKUP_ROOT/dell/$TYPE"
    mkdir -p "$dest"
    
    log "Backing up Dell clawd workspace via SSH..."
    ssh -o ConnectTimeout=30 dell "powershell Compress-Archive -Path C:/Users/tommi/clawd -DestinationPath C:/Users/tommi/clawd_backup.zip -Force" && \
    scp dell:C:/Users/tommi/clawd_backup.zip "$dest/dell_clawd_$TIMESTAMP.zip" 2>/dev/null || {
        log "WARNING: Dell backup failed (might be offline)"
        return 0
    }
    
    log "Dell backup complete: $dest"
}

# Backup Mac Pro via SSH
backup_mac_pro() {
    local dest="$BACKUP_ROOT/mac-pro/$TYPE"
    mkdir -p "$dest"
    
    log "Backing up Mac Pro openclaw config via SSH..."
    ssh -o ConnectTimeout=30 administrator@100.64.58.30 \
        "tar -czf - .openclaw/ 2>/dev/null" > "$dest/mac_pro_$TIMESTAMP.tar.gz" 2>/dev/null || {
        log "WARNING: Mac Pro backup failed (might be offline)"
        return 0
    }
    
    log "Mac Pro backup complete: $dest"
}

# Cleanup old backups based on retention
cleanup() {
    local dir="$1"
    local keep="$2"
    
    if [ -d "$dir" ]; then
        local count=$(ls -1 "$dir"/*.tar.gz "$dir"/*.zip 2>/dev/null | wc -l)
        if [ $count -gt $keep ]; then
            log "Cleaning up $dir (keeping $keep, have $count)"
            ls -1t "$dir"/*.tar.gz "$dir"/*.zip 2>/dev/null | tail -n +$((keep + 1)) | xargs rm -f
        fi
    fi
}

# Mirror to Mac Pro
mirror_to_mac_pro() {
    log "Mirroring backups to Mac Pro..."
    rsync -avz --delete \
        "$BACKUP_ROOT/mac-mini/" \
        "$BACKUP_ROOT/dell/" \
        "$BACKUP_ROOT/mac-pro/" \
        administrator@100.64.58.30:~/backups/ 2>/dev/null || {
        log "WARNING: Mirror to Mac Pro failed"
        return 0
    }
    log "Mirror complete"
}

# Main execution
main() {
    log "=== Starting $TYPE backup ==="
    
    # Run backups
    backup_mac_mini
    backup_dell
    backup_mac_pro
    
    # Cleanup based on type
    case $TYPE in
        incremental)
            cleanup "$BACKUP_ROOT/mac-mini/incremental" $INCREMENTAL_KEEP
            cleanup "$BACKUP_ROOT/dell/incremental" $INCREMENTAL_KEEP
            cleanup "$BACKUP_ROOT/mac-pro/incremental" $INCREMENTAL_KEEP
            ;;
        daily)
            cleanup "$BACKUP_ROOT/mac-mini/daily" $DAILY_KEEP
            cleanup "$BACKUP_ROOT/dell/daily" $DAILY_KEEP
            cleanup "$BACKUP_ROOT/mac-pro/daily" $DAILY_KEEP
            mirror_to_mac_pro
            ;;
        weekly)
            cleanup "$BACKUP_ROOT/mac-mini/weekly" $WEEKLY_KEEP
            cleanup "$BACKUP_ROOT/dell/weekly" $WEEKLY_KEEP
            cleanup "$BACKUP_ROOT/mac-pro/weekly" $WEEKLY_KEEP
            mirror_to_mac_pro
            ;;
        monthly)
            cleanup "$BACKUP_ROOT/mac-mini/monthly" $MONTHLY_KEEP
            cleanup "$BACKUP_ROOT/dell/monthly" $MONTHLY_KEEP
            cleanup "$BACKUP_ROOT/mac-pro/monthly" $MONTHLY_KEEP
            mirror_to_mac_pro
            ;;
    esac
    
    log "=== $TYPE backup complete ==="
}

main
