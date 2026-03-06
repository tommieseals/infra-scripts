#!/bin/bash
echo "🔍 AUTOMATION STATUS CHECK"
echo "=========================="
echo ""

# Email
echo "📧 Email Automation:"
if bash ~/clawd/scripts/auto-email-check.sh 2>&1 | grep -qE "urgent|No"; then
    echo "   ✅ Working"
else
    echo "   ❌ Failed"
fi

# Financial
echo ""
echo "💰 Financial Monitor:"
if bash ~/clawd/scripts/auto-financial-monitor.sh 2>&1 | grep -q "Dell"; then
    echo "   ✅ Working"
else
    echo "   ❌ Failed"
fi

# Cron
echo ""
echo "⏰ Scheduled Jobs:"
JOBS=$(crontab -l 2>/dev/null | grep -cE "email-auto|financial-auto")
echo "   $JOBS/2 active"

# Last runs
echo ""
echo "📝 Recent Activity:"
[ -f ~/clawd/logs/email-auto.log ] && echo "   Email: $(tail -1 ~/clawd/logs/email-auto.log 2>/dev/null | cut -c1-50)"
[ -f ~/clawd/logs/financial-auto.log ] && echo "   Finance: $(tail -1 ~/clawd/logs/financial-auto.log 2>/dev/null | cut -c1-50)"

echo ""
echo "=========================="
