#!/bin/bash
# Job Hunting Dashboard - Quick status overview

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 JOB HUNTING DASHBOARD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# PROJECT LEGION STATUS
if [ -f ~/clawd/memory/legion-pipeline-update.json ]; then
  READY=$(jq -r '.latest_discovery.ready_for_review // 0' ~/clawd/memory/legion-pipeline-update.json)
  QUALIFIED=$(jq -r '.latest_discovery.qualified // 0' ~/clawd/memory/legion-pipeline-update.json)
  TOTAL=$(jq -r '.latest_discovery.jobs_found // 0' ~/clawd/memory/legion-pipeline-update.json)
  TIMESTAMP=$(jq -r '.timestamp' ~/clawd/memory/legion-pipeline-update.json)
  
  echo "📋 PROJECT LEGION"
  echo "  Ready for review: $READY jobs"
  echo "  Qualified: $QUALIFIED"
  echo "  Total found: $TOTAL"
  echo "  Last updated: $TIMESTAMP"
  
  if [ "$READY" -gt 0 ]; then
    echo "  ⚠️  ACTION NEEDED: Review $READY jobs"
  fi
else
  echo "📋 PROJECT LEGION: No data"
fi

echo ""

# GMAIL STATUS
if gog auth list 2>/dev/null | grep -q "tommieseals7700@gmail.com"; then
  echo "📧 GMAIL: ✅ Authenticated"
  
  # Try to get unread count
  UNREAD=$(gog gmail messages search "is:unread" --account tommieseals7700@gmail.com 2>/dev/null | wc -l | tr -d ' ')
  if [ "$UNREAD" -gt 0 ]; then
    echo "  Unread: $UNREAD messages"
  fi
else
  echo "📧 GMAIL: ❌ Not authenticated"
  echo "  Run: gog auth add tommieseals7700@gmail.com --services gmail"
fi

echo ""

# IT DEPARTMENT STATUS
if [ -f ~/clawd/memory/it-department-report.json ]; then
  STATUS=$(jq -r '.status' ~/clawd/memory/it-department-report.json)
  ISSUES=$(jq -r '.summary.total_issues' ~/clawd/memory/it-department-report.json)
  ALERTS=$(jq -r '.summary.total_alerts' ~/clawd/memory/it-department-report.json)
  
  echo "🖥️  IT DEPARTMENT: $STATUS"
  if [ "$ISSUES" -gt 0 ] || [ "$ALERTS" -gt 0 ]; then
    echo "  Issues: $ISSUES | Alerts: $ALERTS"
  fi
else
  echo "🖥️  IT DEPARTMENT: No data"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
