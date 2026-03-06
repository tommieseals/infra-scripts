#!/bin/bash
AUDIT_LOG="$HOME/clawd/logs/audit.log"
STATE_DIR="$HOME/clawd/logs/.audit-state"
mkdir -p "$STATE_DIR"

log_entry() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" >> "$AUDIT_LOG"
}

collect_ssh_logins() {
    log show --predicate 'process == "sshd"' --last 1h 2>/dev/null | grep -E "(Accepted|Failed|session)" | head -20 | while read -r line; do
        log_entry "SSH" "$line"
    done
}

collect_dashboard_access() {
    pm2_log="$HOME/.pm2/logs/legion-dashboard-out.log"
    if [[ -f "$pm2_log" ]]; then
        tail -50 "$pm2_log" 2>/dev/null | grep -E "(GET|POST|PUT|DELETE|login|auth)" | tail -10 | while read -r line; do
            log_entry "DASHBOARD" "$line"
        done
    fi
}

collect_api_calls() {
    n8n_log="$HOME/.pm2/logs/n8n-out.log"
    if [[ -f "$n8n_log" ]]; then
        tail -100 "$n8n_log" 2>/dev/null | grep -iE "(webhook|trigger|execution)" | tail -10 | while read -r line; do
            log_entry "API" "$line"
        done
    fi
    docker logs legion-dashboard --tail 20 2>/dev/null | grep -iE "(api|request|webhook)" | while read -r line; do
        log_entry "API" "$line"
    done
}

collect_file_changes() {
    last_check="$STATE_DIR/files_last_check"
    now=$(date +%s)
    since_minutes=60
    if [[ -f "$last_check" ]]; then
        last_time=$(cat "$last_check")
        since_minutes=$(( (now - last_time) / 60 + 1 ))
    fi
    find "$HOME/clawd" -type f -mmin -"$since_minutes" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/logs/*" -not -name "*.log" 2>/dev/null | while read -r file; do
        log_entry "FILE_CHANGE" "Modified: $file"
    done
    echo "$now" > "$last_check"
}

log_entry "AUDIT" "=== Audit collection started ==="
collect_ssh_logins
collect_dashboard_access
collect_api_calls
collect_file_changes
log_entry "AUDIT" "=== Audit collection completed ==="