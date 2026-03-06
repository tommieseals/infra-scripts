#!/bin/bash
# Weekly Security Audit Wrapper
# Runs security-audit.sh and sends summary to Telegram

LOG_FILE="/Users/tommie/clawd/logs/security-audit.log"
DATE_STR=$(date '+%Y-%m-%d')
REPORT_FILE="/Users/tommie/clawd/memory/security-audit-${DATE_STR}.md"
TELEGRAM_BOT="YOUR_TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT="-1003779327245"

echo "[$(date)] Starting weekly security audit..." >> "$LOG_FILE"

# Run the security audit
cd /Users/tommie/clawd
/Users/tommie/clawd/scripts/security-audit.sh >> "$LOG_FILE" 2>&1
ISSUES_COUNT=$?

# Additional security checks

# Check firewall status
echo "" >> "$REPORT_FILE"
echo "## 6. Firewall Status" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled")
[ -z "$FIREWALL_STATUS" ] && FIREWALL_STATUS="unknown"
echo "**macOS Firewall:** ${FIREWALL_STATUS}" >> "$REPORT_FILE"

# Check exposed ports via netstat
echo "" >> "$REPORT_FILE"
echo "## 7. Exposed Ports" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
netstat -an | grep LISTEN | head -20 >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"

# Check SSH attempts
echo "" >> "$REPORT_FILE"
echo "## 8. Recent SSH Activity" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
last -10 | head -15 >> "$REPORT_FILE"

# Commit the report
cd /Users/tommie/clawd
git add "memory/security-audit-${DATE_STR}.md" 2>/dev/null
git commit -m "Security audit ${DATE_STR}" 2>/dev/null

# Build Telegram summary
if [ "$ISSUES_COUNT" -eq 0 ]; then
    STATUS="✅ No issues found"
else
    STATUS="⚠️ ${ISSUES_COUNT} issues require attention"
fi

TELEGRAM_MSG="🔒 *Weekly Security Audit Complete*
📅 Date: ${DATE_STR}

${STATUS}

📋 Report saved to: memory/security-audit-${DATE_STR}.md

Checks performed:
• Hardcoded secrets scan
• .gitignore coverage
• Git history scan
• Network exposure
• Firewall status
• Exposed ports"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT}" \
    -d "parse_mode=Markdown" \
    --data-urlencode "text=${TELEGRAM_MSG}" > /dev/null

echo "[$(date)] Security audit complete, ${ISSUES_COUNT} issues found" >> "$LOG_FILE"
