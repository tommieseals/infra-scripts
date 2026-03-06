#!/bin/bash
# Sync local shared-brain to/from Mac Pro (with git)
# Usage: sync-shared-brain.sh [push|pull|status]

LOCAL_PATH="$HOME/clawd/shared-brain"
REMOTE_HOST="administrator@100.101.89.80"
REMOTE_PATH="~/shared-brain"

ACTION="${1:-pull}"

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

case "$ACTION" in
    push)
        log "Pushing local changes to Mac Pro..."
        
        # Copy files
        scp -r "$LOCAL_PATH"/* "$REMOTE_HOST:$REMOTE_PATH/"
        
        # Commit on remote
        ssh "$REMOTE_HOST" "cd $REMOTE_PATH && git add -A && git commit -m 'Update from Mac Mini - $(date '+%Y-%m-%d %H:%M')' 2>/dev/null || echo 'No changes to commit'"
        
        log "Done! Changes pushed and committed."
        ;;
    pull)
        log "Pulling latest from Mac Pro..."
        
        # Ensure local directory exists
        mkdir -p "$LOCAL_PATH"
        
        # Pull files
        scp -r "$REMOTE_HOST:$REMOTE_PATH"/* "$LOCAL_PATH/"
        
        log "Done! Local copy updated."
        ;;
    status)
        log "Checking shared-brain status..."
        
        # Show latest commits
        ssh "$REMOTE_HOST" "cd $REMOTE_PATH && git log -3 --format='%h %s (%cr by %an)'"
        
        # Show changed files
        ssh "$REMOTE_HOST" "cd $REMOTE_PATH && git status -s"
        ;;
    *)
        echo "Usage: $0 [push|pull|status]"
        exit 1
        ;;
esac
