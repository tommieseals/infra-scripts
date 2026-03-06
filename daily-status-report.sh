#!/bin/bash
# Daily Status Report Generator
# Run this anytime to get a comprehensive status overview

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          CLAWDBOT INFRASTRUCTURE STATUS REPORT               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Generated: $(date '+%A, %B %d, %Y - %I:%M %p %Z')"
echo ""

# System Health
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏥 SYSTEM HEALTH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# IT Department Status
if [ -f ~/clawd/memory/it-department-report.json ]; then
    IT_STATUS=$(jq -r '.status' ~/clawd/memory/it-department-report.json)
    ISSUES=$(jq -r '.summary.total_issues' ~/clawd/memory/it-department-report.json)
    TECHS=$(jq -r '.technicians_active' ~/clawd/memory/it-department-report.json)
    
    if [ "$IT_STATUS" = "healthy" ]; then
        echo "✅ IT Department: HEALTHY ($TECHS technicians active)"
    else
        echo "⚠️  IT Department: $IT_STATUS ($ISSUES issues)"
    fi
fi

# Disk Space
DISK_USED=$(df -h / | tail -1 | awk '{print $5}')
DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')
echo "💾 Disk: $DISK_USED used, $DISK_FREE free"

# Memory
if [ -f ~/shared-memory/systems.json ]; then
    MEM_FREE=$(grep -A5 '"role": "systems"' ~/shared-memory/systems.json | grep memory_free_pct | head -1 | grep -oE '[0-9]+' || echo "unknown")
    if [ "$MEM_FREE" != "unknown" ]; then
        echo "🧠 Memory: ${MEM_FREE}% free"
    else
        echo "🧠 Memory: Status unavailable"
    fi
fi

# Ollama Status
if pgrep -x "ollama" > /dev/null; then
    echo "🤖 Ollama: Running"
else
    echo "⚠️  Ollama: Not running"
fi

echo ""

# Project Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 PROJECT STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# PROJECT LEGION
if [ -f ~/clawd/memory/legion-pipeline-update.json ]; then
    LEGION_STATUS=$(jq -r '.status' ~/clawd/memory/legion-pipeline-update.json)
    JOBS_READY=$(jq -r '.latest_discovery.ready_for_review' ~/clawd/memory/legion-pipeline-update.json)
    DB_RECORDS=$(jq -r '.database_records' ~/clawd/memory/legion-pipeline-update.json)
    
    echo "🦖 PROJECT LEGION: $LEGION_STATUS"
    echo "   └─ $JOBS_READY jobs ready for review"
    echo "   └─ $DB_RECORDS total job records"
fi

# Check for other project indicators
if [ -d ~/clawd/shared-brain/projects ]; then
    echo ""
    echo "📁 Active Projects (from shared-brain):"
    ls ~/clawd/shared-brain/projects/*.md 2>/dev/null | while read file; do
        PROJECT=$(basename "$file" .md)
        echo "   • $PROJECT"
    done
fi

echo ""

# Network Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 NETWORK & SECURITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f ~/shared-memory/security.json ]; then
    SEC_STATUS=$(grep -A3 '"role": "security"' ~/shared-memory/security.json | grep '"status"' | head -1 | grep -oE '"[a-z_]+"' | tail -1 | tr -d '"')
    OPEN_PORTS=$(head -10 ~/shared-memory/security.json | grep '"ports"' | head -1 | grep -oE '[0-9]+' || echo "0")
    echo "🔐 Security: ${SEC_STATUS:-unknown} (${OPEN_PORTS} open ports)"
fi

if [ -f ~/shared-memory/network.json ]; then
    NET_STATUS=$(grep -A3 '"role": "network"' ~/shared-memory/network.json | grep '"status"' | head -1 | grep -oE '"[a-z_]+"' | tail -1 | tr -d '"')
    echo "📡 Network: ${NET_STATUS:-unknown}"
fi

echo ""

# Recent Activity
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 TODAY'S ACTIVITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f ~/clawd/memory/$(date +%Y-%m-%d).md ]; then
    echo "✅ Daily log created: memory/$(date +%Y-%m-%d).md"
else
    echo "⚠️  No daily log for today yet"
fi

# LinkedIn automation
if [ -f ~/job-hunter-system/logs/recruiter_following.log ]; then
    LAST_RUN=$(tail -1 ~/job-hunter-system/logs/recruiter_following.log | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}')
    echo "🔗 LinkedIn automation last run: $LAST_RUN"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Quick Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ~/clawd/scripts/proactive-monitor.sh    # Run health checks"
echo "  ~/clawd/scripts/sync-shared-brain.sh pull  # Sync knowledge"
echo "  cat ~/clawd/memory/$(date +%Y-%m-%d).md       # View today's log"
echo ""
