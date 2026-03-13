#!/bin/bash
# Monitor for bottom bitch bot activity and alert when it comes back online

TELEGRAM_BOT_TOKEN="8392398778:AAH5lan45kR-VT74d3OiXAAIxlPyR4skGzU"
YOUR_CHAT_ID="939543801"
GROUP_CHAT_ID="-5052671848"
LAST_UPDATE_FILE="/tmp/bottom-bitch-last-update.txt"

# Get last update ID
if [ -f "$LAST_UPDATE_FILE" ]; then
    LAST_UPDATE=$(cat "$LAST_UPDATE_FILE")
else
    LAST_UPDATE=0
fi

# Check for new messages from bottom bitch bot
UPDATES=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${LAST_UPDATE}&limit=10")

# Look for messages from bottom bitch bot in the group
BOT_ACTIVE=$(echo "$UPDATES" | grep -c "Thats_My_Bottom_Bitch_bot")

if [ "$BOT_ACTIVE" -gt 0 ]; then
    # Bot is active! Alert user
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${YOUR_CHAT_ID}" \
        -d "text=✅ @Thats_My_Bottom_Bitch_bot is BACK ONLINE! Detected activity in group chat."
    
    # Update last seen
    NEW_UPDATE=$(echo "$UPDATES" | python3 -c "import sys, json; data=json.load(sys.stdin); print(max([u['update_id'] for u in data['result']], default=0)+1)" 2>/dev/null || echo "$LAST_UPDATE")
    echo "$NEW_UPDATE" > "$LAST_UPDATE_FILE"
    exit 0
fi

# Still offline - no action needed
exit 1
