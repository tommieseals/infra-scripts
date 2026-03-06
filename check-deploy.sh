#!/bin/bash
#==============================================================================
# Clawd Auto-Deploy Check (for cron)
# Checks for git updates and deploys if changes found
# 
# Add to crontab: */15 * * * * ~/clawd/scripts/check-deploy.sh
#==============================================================================

CLAWD_DIR="$HOME/clawd"
LOG_FILE="$CLAWD_DIR/logs/auto-deploy.log"
DEPLOY_SCRIPT="$CLAWD_DIR/scripts/deploy.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Check if remote is configured
cd "$CLAWD_DIR"
if ! git remote get-url origin &>/dev/null; then
    # No remote configured, exit silently
    exit 0
fi

# Fetch and check for changes
git fetch origin 2>/dev/null

LOCAL=$(git rev-parse HEAD)
BRANCH=$(git branch --show-current)
REMOTE=$(git rev-parse "origin/$BRANCH" 2>/dev/null)

if [ -z "$REMOTE" ]; then
    exit 0
fi

if [ "$LOCAL" != "$REMOTE" ]; then
    log "Changes detected! Local: $LOCAL, Remote: $REMOTE"
    log "Starting auto-deploy..."
    
    # Run deploy script
    "$DEPLOY_SCRIPT" 2>&1 | while read line; do
        log "$line"
    done
    
    log "Auto-deploy complete"
else
    # Optional: uncomment to log every check
    # log "No changes (at $LOCAL)"
    :
fi
