#!/bin/bash
# Security Audit Runner with Notification
# Runs audit and notifies via Clawdbot if issues found

AUDIT_SCRIPT="/Users/tommie/clawd/scripts/security-audit.sh"
ALERT_SCRIPT="/Users/tommie/clawd/scripts/security-alert.sh"
REPORT_DIR="/Users/tommie/clawd/memory"
TODAY=$(date +%Y-%m-%d)
REPORT="$REPORT_DIR/security-audit-$TODAY.md"

# Run the audit
$AUDIT_SCRIPT
ISSUES=$?

# If issues found, trigger alert
if [ $ISSUES -gt 0 ]; then
    echo "Security audit found $ISSUES issue(s) - report at $REPORT"
    $ALERT_SCRIPT "$REPORT" "$ISSUES"
    
    # Trigger Clawdbot wake event via cron API if available
    # This will be picked up by heartbeat checks
fi

exit 0
