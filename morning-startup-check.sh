#!/bin/bash
# Morning Startup Check - Runs at 6:00 AM
# Verifies all systems before the day starts

LOG=~/clawd/logs/morning-startup.log
echo "=== MORNING STARTUP CHECK - $(date) ===" >> $LOG

ISSUES=0

# Check 1: Email access
if python3 -c "import imaplib; m=imaplib.IMAP4_SSL('imap.gmail.com'); m.login('tommieseals7700@gmail.com','pxtafuqxzjfegimj'); m.select('INBOX'); m.close(); m.logout()" 2>/dev/null; then
    echo "✅ Email access: OK" >> $LOG
else
    echo "❌ Email access: FAILED" >> $LOG
    ((ISSUES++))
fi

# Check 2: Dell connectivity
if ssh -o ConnectTimeout=5 dell 'echo ok' 2>/dev/null | grep -q "ok"; then
    echo "✅ Dell SSH: OK" >> $LOG
else
    echo "❌ Dell SSH: FAILED" >> $LOG
    ((ISSUES++))
fi

# Check 3: Vault accessible
if ssh dell 'cd C:\Users\tommi\clawd\project-vault && python vault.py --help' 2>&1 | grep -q "usage"; then
    echo "✅ Vault: OK" >> $LOG
else
    echo "❌ Vault: FAILED" >> $LOG
    ((ISSUES++))
fi

# Check 4: Cron jobs
CRON_COUNT=$(crontab -l 2>/dev/null | grep -cE "auto-email|auto-financial")
if [ "$CRON_COUNT" -ge 2 ]; then
    echo "✅ Cron jobs: OK ($CRON_COUNT active)" >> $LOG
else
    echo "❌ Cron jobs: FAILED (only $CRON_COUNT found)" >> $LOG
    ((ISSUES++))
fi

echo "=== RESULT: $ISSUES issues found ===" >> $LOG

if [ $ISSUES -gt 0 ]; then
    echo "⚠️ STARTUP ISSUES DETECTED - Check ~/clawd/logs/morning-startup.log"
    exit 1
else
    echo "✅ ALL SYSTEMS GO"
    exit 0
fi
