#!/bin/bash
# Check for pending security alerts
# Called by Clawdbot during heartbeat checks

ALERT_FILE="/Users/tommie/clawd/memory/security-alert-pending.txt"
STATE_FILE="/Users/tommie/clawd/memory/heartbeat-state.json"
REPORT_DIR="/Users/tommie/clawd/memory"
TODAY=$(date +%Y-%m-%d)
LATEST_REPORT="$REPORT_DIR/security-audit-$TODAY.md"

# Check if there's a pending alert
if [ -f "$ALERT_FILE" ]; then
    cat "$ALERT_FILE"
    rm "$ALERT_FILE"
    exit 0
fi

# Check for today's report if no pending alert
if [ -f "$LATEST_REPORT" ]; then
    # Extract issue count from report
    ISSUE_COUNT=$(grep "Total Issues Found:" "$LATEST_REPORT" | grep -o '[0-9]\+')
    
    if [ -n "$ISSUE_COUNT" ] && [ "$ISSUE_COUNT" -gt 0 ]; then
        # Check if we've already alerted about this report
        if ! grep -q "\"$TODAY\"" "$STATE_FILE" 2>/dev/null; then
            # New report with issues - alert
            SUMMARY=$(grep -A 10 "## 5. Summary" "$LATEST_REPORT" | head -15)
            echo "🚨 **Security Audit Alert**"
            echo ""
            echo "**Issues Found:** $ISSUE_COUNT"
            echo ""
            echo "$SUMMARY"
            echo ""
            echo "📄 Full report: \`security-audit-$TODAY.md\`"
            
            # Mark as alerted
            jq ".alertedReports += [\"$TODAY\"]" "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
            exit 0
        fi
    fi
fi

# No alerts
exit 1
