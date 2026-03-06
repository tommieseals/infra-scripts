#!/bin/bash
# Security Alert Script - Notify via Telegram when issues are found
# Called by security-audit-notify.sh when issues detected

REPORT="$1"
ISSUES="$2"

if [ -z "$REPORT" ] || [ -z "$ISSUES" ]; then
    echo "Usage: $0 <report-file> <issue-count>"
    exit 1
fi

if [ ! -f "$REPORT" ]; then
    echo "Report file not found: $REPORT"
    exit 1
fi

# Extract summary from report
SUMMARY=$(grep -A 10 "## 5. Summary" "$REPORT" | head -15)

# Build alert message
MESSAGE="🚨 **Security Audit Alert**

**Issues Found:** $ISSUES

$SUMMARY

📄 Full report: \`$(basename "$REPORT")\`

Run \`cat /Users/tommie/clawd/memory/$(basename "$REPORT")\` for details."

# Write to temp file for Clawdbot to pick up via wake event
ALERT_FILE="/Users/tommie/clawd/memory/security-alert-pending.txt"
echo "$MESSAGE" > "$ALERT_FILE"

echo "Alert queued: $ALERT_FILE"
exit 0
