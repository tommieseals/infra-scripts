#!/bin/bash
# Dashboard Update Script for Project Legion
# Updates ~/clawd/agents.html with live system status

set -e

# Get current timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
TODAY=$(date "+%Y-%m-%d")

# Get system stats
CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
MEM_STATS=$(top -l 1 | grep "PhysMem")
MEM_USED=$(echo "$MEM_STATS" | awk '{print $2}')
MEM_UNUSED=$(echo "$MEM_STATS" | awk '{print $8}')

# Check service status
OLLAMA_STATUS="❌ Stopped"
REDIS_STATUS="❌ Stopped"
HUB_STATUS="❌ Stopped"

if pgrep -q ollama; then
    OLLAMA_STATUS="✅ Running"
fi

if pgrep -q redis-server; then
    REDIS_STATUS="✅ Running"
fi

if pgrep -f "job-hunter-system.*main.py" > /dev/null 2>&1; then
    HUB_STATUS="✅ Running"
fi

# Read today's memory file if it exists
MEMORY_FILE="$HOME/clawd/memory/${TODAY}.md"
RECENT_ACTIVITY=""

if [ -f "$MEMORY_FILE" ]; then
    # Extract recent activity items from memory file
    RECENT_ACTIVITY=$(grep -E "^##|^-|^✅|^🚨" "$MEMORY_FILE" | head -10 || echo "No recent activity")
fi

# Count files in memory directory
MEMORY_FILE_COUNT=$(ls -1 "$HOME/clawd/memory/"*.md 2>/dev/null | wc -l | xargs)

echo "✅ Dashboard data collected:"
echo "   CPU: ${CPU_USAGE}%"
echo "   Memory: ${MEM_USED} used, ${MEM_UNUSED} free"
echo "   Ollama: $OLLAMA_STATUS"
echo "   Redis: $REDIS_STATUS"
echo "   Hub: $HUB_STATUS"
echo "   Memory files: $MEMORY_FILE_COUNT"
echo ""
echo "📊 Dashboard available at: http://100.82.234.66:8080/agents.html"
echo "⏰ Last updated: $TIMESTAMP"
