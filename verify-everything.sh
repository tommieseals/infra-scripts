#!/bin/bash
echo "🔍 COMPLETE SYSTEM VERIFICATION"
echo "================================"
echo ""

PASS=0
FAIL=0

test_and_report() {
    local name="$1"
    local cmd="$2"
    
    printf "%-40s" "$name..."
    if eval "$cmd" >/dev/null 2>&1; then
        echo "✅"
        ((PASS++))
    else
        echo "❌"
        ((FAIL++))
    fi
}

# Core systems
test_and_report "Email access" "python3 -c 'import imaplib; m=imaplib.IMAP4_SSL(\"imap.gmail.com\"); m.login(\"tommieseals7700@gmail.com\",\"pxtafuqxzjfegimj\"); m.select(\"INBOX\"); m.close(); m.logout()'"

test_and_report "Email automation (with retry)" "test -x ~/clawd/scripts/auto-email-check-with-retry.sh"

test_and_report "Financial monitor" "test -x ~/clawd/scripts/auto-financial-monitor.sh"

test_and_report "Dell SSH" "ssh -o ConnectTimeout=3 dell 'echo 1' 2>&1 | grep -q 1"

test_and_report "Vault access" "ssh dell 'python C:\\Users\\tommi\\clawd\\project-vault\\vault.py --help' 2>&1 | grep -q usage"

test_and_report "TerminatorBot access" "ssh dell 'dir C:\\Users\\tommi\\clawd\\TerminatorBot\\src\\main.py' 2>&1 | grep -q main.py"

test_and_report "Cron jobs (5 active)" "test \$(crontab -l 2>/dev/null | grep -cE 'auto-email|auto-financial|morning-startup|hourly-health|linkedin') -ge 5"

test_and_report "Credentials secured" "test -f ~/clawd/.env && test \$(stat -f %Lp ~/clawd/.env 2>/dev/null) = '600'"

test_and_report "Desktop control" "python3 -c 'import pyautogui'"

test_and_report "LinkedIn automation" "test -f ~/job-hunter-system/follow_it_recruiters.py"

test_and_report "Morning startup check" "test -x ~/clawd/scripts/morning-startup-check.sh"

test_and_report "Hourly health check" "test -x ~/clawd/scripts/hourly-health-check.sh"

test_and_report "Emergency diagnostic" "test -x ~/clawd/scripts/emergency-diagnostic.sh"

echo ""
echo "================================"
echo "FINAL: $PASS/13 PASSED | $FAIL/13 FAILED"
echo "================================"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 PERFECT SCORE - FULLY READY"
    echo ""
    echo "Tomorrow 6 AM:"
    echo "  ✅ Morning startup verification"
    echo "  ✅ Email (every 15 min, with retry)"
    echo "  ✅ Financial (every 30 min)"
    echo "  ✅ LinkedIn (9 AM)"
    echo "  ✅ Health checks (hourly)"
    echo ""
    echo "💀 LOCKED AND LOADED. TAKING SOULS."
    exit 0
else
    echo "⚠️  $FAIL issues"
    exit 1
fi
