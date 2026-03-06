#!/bin/bash
# Proactive System Monitor - Reads reports and acts on issues
# Should run every heartbeat

REPORT_DIR="/Users/tommie/shared-memory"
ALERT_LOG="/Users/tommie/clawd/logs/proactive-alerts.log"

echo "[$(date)] Starting proactive monitoring..." >> "$ALERT_LOG"

# Check ACTUAL memory pressure (not broken free RAM metric)
# The file is an array - get the last entry
MEM_FREE_PCT=$(jq -r '.[-1].memory_free_pct // 100' "$REPORT_DIR/systems.json" 2>/dev/null)
SYSTEM_STATUS=$(jq -r '.[-1].ollama_status // "unknown"' "$REPORT_DIR/systems.json" 2>/dev/null)

# Convert to integer (remove decimal)
MEM_FREE_INT=${MEM_FREE_PCT%.*}
MEM_FREE_INT=${MEM_FREE_INT:-0}

# Alert if RAM usage > 85%
if [ "$MEM_FREE_INT" -lt 15 ]; then
    echo "[$(date)] ⚠️ MEMORY PRESSURE HIGH: ${MEM_FREE_PCT}% free (status: $SYSTEM_STATUS)" >> "$ALERT_LOG"
    # Alert to Telegram
    curl -s -X POST "https://api.telegram.org/botYOUR_TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=-1003779327245" \
        -d "text=⚠️ Memory Pressure Alert: ${MEM_FREE_PCT}% free on Mac Mini. Status: $SYSTEM_STATUS" > /dev/null
    
    # Try to free memory
    echo "[$(date)] Attempting to free memory..." >> "$ALERT_LOG"
    # Kill memory-heavy processes if needed
    # docker restart n8n (if safe)
else
    echo "[$(date)] ✅ Memory healthy: ${MEM_FREE_PCT}% free" >> "$ALERT_LOG"
fi

# Check network status from network.json
DELL_LATENCY=$(jq -r '.[0].dell_latency // "unknown"' "$REPORT_DIR/network.json" 2>/dev/null)
CLOUD_LATENCY=$(jq -r '.[0].cloud_latency // "unknown"' "$REPORT_DIR/network.json" 2>/dev/null)

if [ "$DELL_LATENCY" = "unreachable" ]; then
    echo "[$(date)] ℹ️ Dell unreachable - likely at home (Houston)" >> "$ALERT_LOG"
fi

# Check for disk space issues
DISK_PERCENT=$(jq -r '.[0].disk_used_percent // 0' "$REPORT_DIR/systems.json" 2>/dev/null)
if [ "$DISK_PERCENT" -lt 15 ]; then
    echo "[$(date)] ⚠️ DISK HIGH: ${DISK_PERCENT}% free" >> "$ALERT_LOG"
    curl -s -X POST "https://api.telegram.org/botYOUR_TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=-1003779327245" \
        -d "text=⚠️ Disk Alert: ${DISK_PERCENT}% free on Mac Mini." > /dev/null
fi

# Check Docker health
bash /Users/tommie/clawd/scripts/docker-monitor.sh >> "$ALERT_LOG" 2>&1

DOCKER_UNHEALTHY=$(jq -r '.unhealthy // 0' "$REPORT_DIR/docker-status.json" 2>/dev/null)
DOCKER_ISSUES=$(jq -r '.issues | length' "$REPORT_DIR/docker-status.json" 2>/dev/null)

if [ "$DOCKER_UNHEALTHY" -gt 0 ] || [ "$DOCKER_ISSUES" -gt 0 ]; then
    echo "[$(date)] ⚠️ DOCKER ISSUES: $DOCKER_UNHEALTHY unhealthy, auto-healed $DOCKER_ISSUES" >> "$ALERT_LOG"
    curl -s -X POST "https://api.telegram.org/botYOUR_TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=-1003779327245" \
        -d "text=🐳 Docker Alert: $DOCKER_UNHEALTHY unhealthy containers, auto-healed $DOCKER_ISSUES issues." > /dev/null
fi

echo "[$(date)] Monitoring complete" >> "$ALERT_LOG"
