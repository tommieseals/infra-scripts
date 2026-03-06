#!/bin/bash
# Log Rotation Script - Keep 7 days of logs

LOG_DIR="$HOME/clawd/logs"
DAYS_TO_KEEP=7
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

echo "[$TIMESTAMP] Starting log rotation..."

# Find and delete directories older than DAYS_TO_KEEP
for host_dir in "$LOG_DIR"/mac-mini "$LOG_DIR"/mac-pro "$LOG_DIR"/dell; do
    if [ -d "$host_dir" ]; then
        echo "  Rotating logs in $host_dir..."
        find "$host_dir" -mindepth 1 -maxdepth 1 -type d -mtime +$DAYS_TO_KEEP -exec rm -rf {} \; 2>/dev/null
    fi
done

# Clean up any orphaned empty directories
find "$LOG_DIR" -type d -empty -delete 2>/dev/null

# Show remaining space
echo "  Log directory size:"
du -sh "$LOG_DIR" 2>/dev/null || echo "    Could not determine size"

echo "[$TIMESTAMP] Log rotation complete."
