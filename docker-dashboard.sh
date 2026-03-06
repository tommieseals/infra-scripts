#!/bin/bash
# Quick Docker Dashboard
# Shows container status, resource usage, and recent logs

echo "🐳 DOCKER DASHBOARD"
echo "=================="
echo ""

echo "📦 CONTAINERS:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"
echo ""

echo "📊 RESOURCE USAGE:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

echo "🔍 RECENT LOGS (n8n-legion):"
docker logs n8n-legion --tail 10 2>&1
echo ""

echo "✅ HEALTH STATUS:"
bash /Users/tommie/clawd/scripts/docker-monitor.sh 2>&1 | grep -E "(healthy|unhealthy|stopped|Auto-healed)"
