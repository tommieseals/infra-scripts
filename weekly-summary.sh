#!/bin/bash
# Weekly Summary Report Generator
# Generates a markdown report of the week's activity
# Reads from memory/*.md files and outputs to memory/weekly-summary-YYYY-MM-DD.md

set -e

CLAWD_DIR="$HOME/clawd"
MEMORY_DIR="$CLAWD_DIR/memory"
SCRIPTS_DIR="$CLAWD_DIR/scripts"
LEGION_DIR="$HOME/job-hunter-system"

# Output file with current date
TODAY=$(date +%Y-%m-%d)
WEEK_START=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d)
OUTPUT_FILE="$MEMORY_DIR/weekly-summary-$TODAY.md"

echo "📊 Generating weekly summary for $WEEK_START to $TODAY..."

# Start the report
{
echo "# Weekly Summary Report"
echo "**Period:** $WEEK_START to $TODAY  "
echo "**Generated:** $(date "+%Y-%m-%d %H:%M:%S %Z")"
echo ""
echo "---"
echo ""
} > "$OUTPUT_FILE"

#######################################
# Section 1: Jobs Discovered (Legion)
#######################################
{
echo "## 🎯 Project Legion - Jobs Discovered"
echo ""
} >> "$OUTPUT_FILE"

if [[ -d "$LEGION_DIR" ]]; then
    # Count jobs from email_jobs.json
    if [[ -f "$LEGION_DIR/data/email_jobs.json" ]]; then
        TOTAL_JOBS=$(grep -c '"url"' "$LEGION_DIR/data/email_jobs.json" 2>/dev/null || echo "0")
        echo "**Total jobs in queue:** $TOTAL_JOBS" >> "$OUTPUT_FILE"
    else
        echo "**Total jobs in queue:** 0 (no data file)" >> "$OUTPUT_FILE"
    fi

    # Count processed jobs
    if [[ -f "$LEGION_DIR/data/processed_jobs.json" ]]; then
        PROCESSED=$(grep -c '"url"' "$LEGION_DIR/data/processed_jobs.json" 2>/dev/null || echo "0")
        echo "**Jobs processed:** $PROCESSED" >> "$OUTPUT_FILE"
    else
        echo "**Jobs processed:** 0" >> "$OUTPUT_FILE"
    fi

    # Count skipped jobs
    if [[ -f "$LEGION_DIR/data/skipped_jobs.json" ]]; then
        SKIPPED=$(grep -c '"url"' "$LEGION_DIR/data/skipped_jobs.json" 2>/dev/null || echo "0")
        echo "**Jobs skipped (non-Easy Apply):** $SKIPPED" >> "$OUTPUT_FILE"
    else
        echo "**Jobs skipped:** 0" >> "$OUTPUT_FILE"
    fi

    # Count resumes generated
    RESUME_COUNT=$(ls -1 "$LEGION_DIR/data/resumes/"*.pdf 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    echo "**Resumes generated:** $RESUME_COUNT" >> "$OUTPUT_FILE"

    # System status
    {
    echo ""
    echo "### Legion System Status"
    } >> "$OUTPUT_FILE"
    
    # Check if services are running
    if pgrep -f "continuous_email_monitor" > /dev/null 2>&1; then
        echo "- ✅ Email Monitor: Running" >> "$OUTPUT_FILE"
    else
        echo "- ❌ Email Monitor: Not running" >> "$OUTPUT_FILE"
    fi
    
    if pgrep -f "it_scheduler" > /dev/null 2>&1; then
        echo "- ✅ IT Scheduler: Running" >> "$OUTPUT_FILE"
    else
        echo "- ❌ IT Scheduler: Not running" >> "$OUTPUT_FILE"
    fi
else
    echo "Legion system directory not found at $LEGION_DIR" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

#######################################
# Section 2: Health Incidents
#######################################
{
echo "## 🏥 Health Incidents"
echo ""
} >> "$OUTPUT_FILE"

# Search memory files for health-related keywords
HEALTH_INCIDENTS=0
for file in "$MEMORY_DIR"/2026-*.md; do
    if [[ -f "$file" ]]; then
        # Get file date
        FILE_DATE=$(basename "$file" .md | cut -d- -f1-3)
        
        # Check if file is within the last 7 days
        if [[ "$FILE_DATE" > "$WEEK_START" || "$FILE_DATE" == "$WEEK_START" ]]; then
            # Search for health-related content
            HEALTH_LINES=$(grep -i -E "(incident|crash|failure|down|offline|panic|critical|emergency)" "$file" 2>/dev/null | head -5)
            if [[ -n "$HEALTH_LINES" ]]; then
                HEALTH_INCIDENTS=$((HEALTH_INCIDENTS + 1))
                {
                echo "### $FILE_DATE"
                echo '```'
                echo "$HEALTH_LINES"
                echo '```'
                echo ""
                } >> "$OUTPUT_FILE"
            fi
        fi
    fi
done

if [[ $HEALTH_INCIDENTS -eq 0 ]]; then
    echo "✅ No major incidents detected this week." >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

#######################################
# Section 3: Uptime Stats
#######################################
{
echo "## ⏱️ Uptime Statistics"
echo ""
} >> "$OUTPUT_FILE"

# System uptime
UPTIME_INFO=$(uptime | sed 's/^[ \t]*//')
echo "**System Uptime:** $UPTIME_INFO" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Check key services
{
echo "### Service Status"
echo "| Service | Status |"
echo "|---------|--------|"
} >> "$OUTPUT_FILE"

# Ollama
if pgrep -f "ollama" > /dev/null 2>&1; then
    echo "| Ollama | ✅ Running |" >> "$OUTPUT_FILE"
else
    echo "| Ollama | ❌ Stopped |" >> "$OUTPUT_FILE"
fi

# Docker
if docker ps > /dev/null 2>&1; then
    DOCKER_CONTAINERS=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    echo "| Docker | ✅ Running ($DOCKER_CONTAINERS containers) |" >> "$OUTPUT_FILE"
else
    echo "| Docker | ❌ Stopped |" >> "$OUTPUT_FILE"
fi

# Clawdbot Gateway
if pgrep -f "clawdbot" > /dev/null 2>&1 || pgrep -f "gateway" > /dev/null 2>&1; then
    echo "| Clawdbot Gateway | ✅ Running |" >> "$OUTPUT_FILE"
else
    echo "| Clawdbot Gateway | ⚠️ Unknown |" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

#######################################
# Section 4: Token Usage Estimates
#######################################
{
echo "## 💰 Token Usage Estimates"
echo ""
} >> "$OUTPUT_FILE"

# Check LLM usage log if it exists
LLM_USAGE_LOG="$CLAWD_DIR/logs/llm-usage.log"
if [[ -f "$LLM_USAGE_LOG" ]]; then
    # Count entries from the past week
    WEEK_ENTRIES=$(awk -v start="$WEEK_START" '$1 >= start' "$LLM_USAGE_LOG" 2>/dev/null | wc -l | tr -d ' ')
    echo "**LLM API calls this week:** $WEEK_ENTRIES" >> "$OUTPUT_FILE"
else
    echo "**LLM usage log not found** - consider setting up tracking" >> "$OUTPUT_FILE"
fi

# Estimate based on memory file sizes (rough proxy for activity)
MEMORY_BYTES=0
MEMORY_FILES=0
for file in "$MEMORY_DIR"/2026-*.md; do
    if [[ -f "$file" ]]; then
        FILE_DATE=$(basename "$file" .md | cut -d- -f1-3)
        if [[ "$FILE_DATE" > "$WEEK_START" || "$FILE_DATE" == "$WEEK_START" ]]; then
            SIZE=$(wc -c < "$file" | tr -d ' ')
            MEMORY_BYTES=$((MEMORY_BYTES + SIZE))
            MEMORY_FILES=$((MEMORY_FILES + 1))
        fi
    fi
done

{
echo ""
echo "### Activity Metrics (Estimated)"
echo "- **Memory files this week:** $MEMORY_FILES"
echo "- **Total bytes logged:** $MEMORY_BYTES"
} >> "$OUTPUT_FILE"

# Rough token estimate (1 token ≈ 4 characters, assume 2x for I/O)
if [[ $MEMORY_BYTES -gt 0 ]]; then
    EST_TOKENS=$((MEMORY_BYTES / 4 * 2))
    echo "- **Estimated tokens (rough):** ~$EST_TOKENS" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

#######################################
# Section 5: Activity Summary
#######################################
{
echo "## 📝 Weekly Activity Summary"
echo ""
echo "### Memory Files Created"
} >> "$OUTPUT_FILE"

# List all memory files from this week
for file in "$MEMORY_DIR"/2026-*.md; do
    if [[ -f "$file" ]]; then
        FILE_DATE=$(basename "$file" .md | cut -d- -f1-3)
        if [[ "$FILE_DATE" > "$WEEK_START" || "$FILE_DATE" == "$WEEK_START" ]]; then
            FILE_SIZE=$(wc -c < "$file" | tr -d ' ')
            FILE_NAME=$(basename "$file")
            # Get first heading if available
            FIRST_HEADING=$(grep -m1 "^##" "$file" 2>/dev/null | sed 's/^## //' || echo "No heading")
            echo "- **$FILE_NAME** ($FILE_SIZE bytes) - $FIRST_HEADING" >> "$OUTPUT_FILE"
        fi
    fi
done

echo "" >> "$OUTPUT_FILE"

#######################################
# Section 6: Key Highlights
#######################################
{
echo "## 🌟 Key Highlights"
echo ""
echo "### Completed Items"
} >> "$OUTPUT_FILE"

# Extract completed items (✅) from memory files
COMPLETED_COUNT=0
for file in "$MEMORY_DIR"/2026-*.md; do
    if [[ -f "$file" ]]; then
        FILE_DATE=$(basename "$file" .md | cut -d- -f1-3)
        if [[ "$FILE_DATE" > "$WEEK_START" || "$FILE_DATE" == "$WEEK_START" ]]; then
            COMPLETED=$(grep "✅" "$file" 2>/dev/null | wc -l | tr -d ' ')
            COMPLETED_COUNT=$((COMPLETED_COUNT + COMPLETED))
        fi
    fi
done
echo "Total completed items: **$COMPLETED_COUNT**" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

#######################################
#######################################
# Section 7: Cost Summary
#######################################
{
echo "## 💰 Cost Summary"
echo ""
if [ -x ~/clawd/scripts/cost-report.sh ]; then
    ~/clawd/scripts/cost-report.sh 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || echo "Cost report unavailable"
else
    echo "Cost tracking not configured"
fi
echo ""
} >> "$OUTPUT_FILE"

# Footer
#######################################
{
echo "---"
echo ""
echo "*Report generated by weekly-summary.sh*"
echo "*Next report: $(date -v+7d +%Y-%m-%d 2>/dev/null || date -d "+7 days" +%Y-%m-%d)*"
} >> "$OUTPUT_FILE"

echo "✅ Report generated: $OUTPUT_FILE"
echo ""
cat "$OUTPUT_FILE"
