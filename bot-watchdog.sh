#!/bin/bash
# Bot Watchdog - Monitors clawdbot-gateway, alerts, waits 10min, then restarts
# Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID as environment variables

TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN:-YOUR_TOKEN_HERE
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID:-YOUR_CHAT_ID
LOCKFILE=/tmp/bot-watchdog.lock
LOG_FILE=/tmp/clawdbot.log

send_telegram() {
    local msg=$1
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage \
        -d chat_id=$TELEGRAM_CHAT_ID \
        -d text=$msg \
        -d parse_mode=Markdown > /dev/null 2>&1
}

# Check if bot is running
if pgrep -x clawdbot-gateway > /dev/null; then
    rm -f $LOCKFILE
    exit 0
fi

# Bot is down - check if we already alerted
if [ -f $LOCKFILE ]; then
    LOCK_TIME=$(cat $LOCKFILE)
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - LOCK_TIME))
    
    if [ $ELAPSED -ge 600 ]; then
        export PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin
        cd /Users/tommie/clawd
        /usr/bin/nohup /opt/homebrew/bin/clawdbot gateway > /tmp/clawdbot.log 2>&1 &
        sleep 5
        
        if pgrep -x clawdbot-gateway > /dev/null; then
            NEW_PID=$(pgrep -x clawdbot-gateway)
            send_telegram ✅ Bot Auto-Restarted (PID: $NEW_PID)
        else
            send_telegram ❌ Auto-Restart FAILED
        fi
        rm -f $LOCKFILE
    fi
    exit 0
fi

CRASH_LOGS=$(tail -30 $LOG_FILE 2>/dev/null | grep -iE error|fail|crash | tail -5)
date +%s > $LOCKFILE
MSG=⚠️ Mac Mini Bot DOWN - Will auto-restart in 10 minutes $ error logs found}
send_telegram $MSG
EOFSCRIPT
head -6 bot-watchdog.sh