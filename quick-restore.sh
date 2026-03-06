#!/bin/bash
# Quick Restore Script
# Usage: quick-restore.sh [incremental|daily|weekly|monthly] [mac-mini|dell|mac-pro|dashboard]

set -e

BACKUP_ROOT="$HOME/backups"
TYPE=${1:-incremental}
TARGET=${2:-dashboard}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# List available backups
list_backups() {
    echo "=== Available Backups ==="
    echo ""
    echo "Incremental (6hr):"
    ls -lt $BACKUP_ROOT/mac-mini/incremental/*.tar.gz 2>/dev/null | head -5 || echo "  None"
    echo ""
    echo "Daily:"
    ls -lt $BACKUP_ROOT/mac-mini/daily/*.tar.gz 2>/dev/null | head -5 || echo "  None"
    echo ""
    echo "Weekly:"
    ls -lt $BACKUP_ROOT/mac-mini/weekly/*.tar.gz 2>/dev/null | head -5 || echo "  None"
    echo ""
    echo "Monthly:"
    ls -lt $BACKUP_ROOT/mac-mini/monthly/*.tar.gz 2>/dev/null | head -5 || echo "  None"
}

# Restore dashboard
restore_dashboard() {
    local backup_dir="$BACKUP_ROOT/mac-mini/$TYPE"
    local latest=$(ls -t "$backup_dir"/dashboard_*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest" ]; then
        log "ERROR: No dashboard backup found in $backup_dir"
        exit 1
    fi
    
    log "Restoring dashboard from: $latest"
    log "Creating backup of current dashboard..."
    mv ~/clawd/dashboard ~/clawd/dashboard.pre-restore-$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    log "Extracting backup..."
    tar -xzf "$latest" -C ~/clawd/
    
    log "Dashboard restored! Restart the server:"
    log "  pkill -f 'node.*server.js' && cd ~/clawd/dashboard && node server.js &"
}

# Restore full clawd workspace
restore_clawd() {
    local backup_dir="$BACKUP_ROOT/mac-mini/$TYPE"
    local latest=$(ls -t "$backup_dir"/clawd_*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest" ]; then
        log "ERROR: No clawd backup found in $backup_dir"
        exit 1
    fi
    
    log "WARNING: This will replace your entire ~/clawd directory!"
    log "Backup file: $latest"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "Aborted."
        exit 0
    fi
    
    log "Creating backup of current clawd..."
    mv ~/clawd ~/clawd.pre-restore-$(date +%Y%m%d_%H%M%S)
    
    log "Extracting backup..."
    tar -xzf "$latest" -C ~/
    
    log "Clawd workspace restored!"
}

# Main
case "$TARGET" in
    list)
        list_backups
        ;;
    dashboard)
        restore_dashboard
        ;;
    clawd|mac-mini)
        restore_clawd
        ;;
    *)
        echo "Usage: $0 [incremental|daily|weekly|monthly] [list|dashboard|clawd]"
        echo ""
        echo "Examples:"
        echo "  $0 list                    # List all backups"
        echo "  $0 incremental dashboard   # Restore dashboard from latest incremental"
        echo "  $0 daily clawd             # Restore full clawd from daily backup"
        ;;
esac
