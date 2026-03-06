#!/bin/bash
AUDIT_LOG="$HOME/clawd/logs/audit.log"
ARCHIVE_DIR="$HOME/clawd/logs/archive"
MAX_ARCHIVES=4
mkdir -p "$ARCHIVE_DIR"

rotate_logs() {
    if [[ ! -f "$AUDIT_LOG" ]]; then
        echo "No audit log to rotate"
        exit 0
    fi
    size=$(stat -f%z "$AUDIT_LOG" 2>/dev/null || stat -c%s "$AUDIT_LOG")
    if [[ $size -gt 1048576 ]] || [[ "$1" == "--force" ]]; then
        timestamp=$(date "+%Y%m%d_%H%M%S")
        gzip -c "$AUDIT_LOG" > "$ARCHIVE_DIR/audit-$timestamp.log.gz"
        cat /dev/null > "$AUDIT_LOG"
        echo "[$(date)] Log rotated" >> "$AUDIT_LOG"
        archive_count=$(ls -1 "$ARCHIVE_DIR"/audit-*.gz 2>/dev/null | wc -l)
        if [[ $archive_count -gt $MAX_ARCHIVES ]]; then
            ls -1t "$ARCHIVE_DIR"/audit-*.gz | tail -n +$((MAX_ARCHIVES + 1)) | xargs rm -f
        fi
        echo "Log rotated: audit-$timestamp.log.gz"
    else
        echo "Log size ($size bytes) below 1MB threshold"
    fi
}
rotate_logs "$@"