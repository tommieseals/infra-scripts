#!/bin/bash
# Auto-commit memory files every 6 hours
# Preserves daily notes and important context

LOG_FILE="/Users/tommie/clawd/logs/auto-commit.log"
MEMORY_DIR="/Users/tommie/clawd/memory"

echo "[$(date)] Starting auto-commit check..." >> "$LOG_FILE"

cd /Users/tommie/clawd || exit 1

# Check for changes in memory directory
CHANGES=$(git status --porcelain memory/ 2>/dev/null | wc -l | tr -d ' ')

if [ "$CHANGES" -gt 0 ]; then
    echo "[$(date)] Found $CHANGES changes in memory/" >> "$LOG_FILE"
    
    # Stage all memory changes
    git add memory/
    
    # Create commit with timestamp
    COMMIT_MSG="Auto-commit memory files ($(date '+%Y-%m-%d %H:%M'))"
    git commit -m "$COMMIT_MSG" >> "$LOG_FILE" 2>&1
    
    # Try to push (non-blocking)
    git push origin main >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        echo "[$(date)] Push failed, will retry later" >> "$LOG_FILE"
    fi
    
    echo "[$(date)] Committed and pushed $CHANGES files" >> "$LOG_FILE"
else
    echo "[$(date)] No changes to commit" >> "$LOG_FILE"
fi
