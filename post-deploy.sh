#!/bin/bash
#==============================================================================
# Post-Deploy Hook - RUNS AFTER EVERY GIT PULL
# Restores dashboard fixes that get overwritten by GitHub pulls
#
# This is CRITICAL because GitHub has old versions and we can't push.
# Every auto-deploy overwrites our fixes - this script restores them.
#==============================================================================

CLAWD_DIR="$HOME/clawd"
SCRIPTS_DIR="$CLAWD_DIR/scripts"
LOG_FILE="$CLAWD_DIR/logs/post-deploy.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================"
log "POST-DEPLOY HOOK STARTING"
log "========================================"

# Run the main post-deploy Python script
if [ -f "$SCRIPTS_DIR/post-deploy.py" ]; then
    log "Running post-deploy.py..."
    python3 "$SCRIPTS_DIR/post-deploy.py"
else
    log "post-deploy.py not found, running fallback fixes..."
    
    # Fallback: at minimum run the nav fix
    if [ -f "$SCRIPTS_DIR/fix-dashboard-nav.py" ]; then
        python3 "$SCRIPTS_DIR/fix-dashboard-nav.py"
    fi
fi

log "========================================"
log "POST-DEPLOY HOOK COMPLETE"
log "========================================"
