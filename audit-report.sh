#!/bin/bash
AUDIT_LOG="$HOME/clawd/logs/audit.log"
REPORT_DIR="$HOME/clawd/logs/reports"
TODAY=$(date "+%Y-%m-%d")
REPORT_FILE="$REPORT_DIR/audit-report-$TODAY.md"
mkdir -p "$REPORT_DIR"

generate_report() {
    echo "# Daily Audit Report - $TODAY" > "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "Host: $(hostname)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [[ ! -f "$AUDIT_LOG" ]]; then
        echo "No audit log found" >> "$REPORT_FILE"
        return
    fi
    
    today_entries=$(grep "^\[$TODAY" "$AUDIT_LOG" 2>/dev/null || true)
    
    echo "## SSH Activity" >> "$REPORT_FILE"
    ssh_count=$(echo "$today_entries" | grep -c "\[SSH\]" 2>/dev/null || echo 0)
    echo "- Total SSH events: $ssh_count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Dashboard Access" >> "$REPORT_FILE"
    dashboard_count=$(echo "$today_entries" | grep -c "\[DASHBOARD\]" 2>/dev/null || echo 0)
    echo "- Total dashboard events: $dashboard_count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## API Activity" >> "$REPORT_FILE"
    api_count=$(echo "$today_entries" | grep -c "\[API\]" 2>/dev/null || echo 0)
    echo "- Total API events: $api_count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## File Changes" >> "$REPORT_FILE"
    file_count=$(echo "$today_entries" | grep -c "\[FILE_CHANGE\]" 2>/dev/null || echo 0)
    echo "- Files modified: $file_count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## System Status" >> "$REPORT_FILE"
    echo "Uptime: $(uptime)" >> "$REPORT_FILE"
    echo "Disk: $(df -h / | tail -1 | awk '{ print $5 }')" >> "$REPORT_FILE"
    echo "Docker: $(docker ps -q 2>/dev/null | wc -l) running" >> "$REPORT_FILE"
}

case "$1" in
    --stdout) generate_report; cat "$REPORT_FILE" ;;
    *) generate_report; echo "Report: $REPORT_FILE" ;;
esac