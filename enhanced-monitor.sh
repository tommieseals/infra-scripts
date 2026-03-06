#!/bin/bash
# Enhanced Infrastructure Monitor - Daily Health Report
# Sends comprehensive summary to Telegram

REPORT_DIR="/Users/tommie/shared-memory"
LOG_FILE="/Users/tommie/clawd/logs/daily-health.log"
DATE_STR=$(date '+%Y-%m-%d %H:%M')
TELEGRAM_BOT="YOUR_TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT="-1003779327245"

echo "[${DATE_STR}] Starting daily health report..." >> "$LOG_FILE"

# Gather system metrics
HOSTNAME=$(hostname)
UPTIME=$(uptime | sed 's/.*up //' | sed 's/,.*//')
LOAD=$(sysctl -n vm.loadavg | awk '{print $2, $3, $4}')
MEM_PRESSURE=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}')
DISK_USED=$(df -h / | tail -1 | awk '{print $5}')

# Docker status
DOCKER_RUNNING=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
DOCKER_UNHEALTHY=$(docker ps --filter 'health=unhealthy' -q 2>/dev/null | wc -l | tr -d ' ')

# Ollama status
OLLAMA_STATUS="Down"
if pgrep -x ollama > /dev/null; then
    OLLAMA_MODELS=$(ollama ps 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
    OLLAMA_STATUS="Running (${OLLAMA_MODELS} models loaded)"
fi

# Network connectivity
TAILSCALE_STATUS=$(tailscale status --json 2>/dev/null | jq -r '.Self.Online // false')
if ping -c 1 -W 2 100.107.231.87 >/dev/null 2>&1; then
    GOOGLE_CLOUD_PING="✅"
else
    GOOGLE_CLOUD_PING="❌"
fi
if ping -c 1 -W 2 100.119.87.108 >/dev/null 2>&1; then
    DELL_PING="✅"
else
    DELL_PING="❌"
fi

# Git status
cd ~/clawd
GIT_CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
LAST_COMMIT=$(git log -1 --format='%ar' 2>/dev/null)
[ -z "$LAST_COMMIT" ] && LAST_COMMIT="unknown"

# Tailscale emoji
if [ "$TAILSCALE_STATUS" = "true" ]; then
    TS_EMOJI="✅"
else
    TS_EMOJI="❌"
fi

# Build report
REPORT="📊 *Daily Health Report* - ${DATE_STR}

🖥️ *System:* ${HOSTNAME}
⏱️ *Uptime:* ${UPTIME}
📈 *Load:* ${LOAD}
💾 *Memory Free:* ${MEM_PRESSURE}
💽 *Disk Used:* ${DISK_USED}

🐳 *Docker:* ${DOCKER_RUNNING} running"

if [ "$DOCKER_UNHEALTHY" -gt 0 ]; then
    REPORT="${REPORT}, ⚠️ ${DOCKER_UNHEALTHY} unhealthy"
fi

REPORT="${REPORT}
🦙 *Ollama:* ${OLLAMA_STATUS}

🌐 *Network:*
• Tailscale: ${TS_EMOJI}
• Google Cloud: ${GOOGLE_CLOUD_PING}
• Dell: ${DELL_PING}

📝 *Git:* ${GIT_CHANGES} uncommitted changes, last commit ${LAST_COMMIT}"

# Check for issues
ISSUES=""
MEM_NUM=${MEM_PRESSURE%\%}
DISK_NUM=${DISK_USED%\%}
[ "$MEM_NUM" -lt 15 ] 2>/dev/null && ISSUES="${ISSUES}
⚠️ Low memory (${MEM_PRESSURE} free)"
[ "$DISK_NUM" -gt 85 ] 2>/dev/null && ISSUES="${ISSUES}
⚠️ High disk usage (${DISK_USED})"
[ "$DOCKER_UNHEALTHY" -gt 0 ] && ISSUES="${ISSUES}
⚠️ Unhealthy containers"

if [ -n "$ISSUES" ]; then
    REPORT="${REPORT}

🚨 *Issues Detected:*${ISSUES}"
else
    REPORT="${REPORT}

✅ *All systems healthy!*"
fi

# Send to Telegram
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT}" \
    -d "parse_mode=Markdown" \
    --data-urlencode "text=${REPORT}" > /dev/null

echo "[$(date)] Health report sent to Telegram" >> "$LOG_FILE"
