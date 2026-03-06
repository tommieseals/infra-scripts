#!/bin/bash
echo "🚨 EMERGENCY DIAGNOSTIC"
echo "======================="
echo ""

echo "1. Email Access:"
python3 -c "import imaplib; m=imaplib.IMAP4_SSL('imap.gmail.com'); m.login('tommieseals7700@gmail.com','pxtafuqxzjfegimj'); print('  ✅ Working')" 2>&1 | grep -E "Working|Error"

echo ""
echo "2. Dell Connection:"
ssh -o ConnectTimeout=5 dell 'echo "  ✅ Connected"' 2>&1 | head -1

echo ""
echo "3. Cron Jobs:"
crontab -l | grep -E "auto-email|auto-financial" | wc -l | xargs echo "  Active jobs:"

echo ""
echo "4. Recent Logs:"
echo "  Email:" $(tail -1 ~/clawd/logs/email-auto.log 2>/dev/null | cut -c1-50)
echo "  Financial:" $(tail -1 ~/clawd/logs/financial-auto.log 2>/dev/null | cut -c1-50)

echo ""
echo "5. Last Email Check:"
ls -lh ~/clawd/logs/email-auto.log 2>/dev/null | awk '{print "  "$6, $7, $8}'

echo ""
echo "======================="
echo "If issues found, text: 'emergency fix needed'"
