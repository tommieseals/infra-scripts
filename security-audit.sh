#!/bin/bash
# Security Audit Script - Daily scan for exposed secrets and vulnerabilities
# Run by Clawdbot Security Officer agent

WORKSPACE="/Users/tommie/clawd"
REPORT="/Users/tommie/clawd/memory/security-audit-$(date +%Y-%m-%d).md"
ISSUES_FOUND=0

echo "# Security Audit Report - $(date)" > "$REPORT"
echo "" >> "$REPORT"

# Function to log findings
log_issue() {
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    echo "⚠️ **ISSUE $ISSUES_FOUND**: $1" >> "$REPORT"
    echo "   - Location: $2" >> "$REPORT"
    echo "   - Details: $3" >> "$REPORT"
    echo "" >> "$REPORT"
}

echo "## 1. Scanning for Hardcoded Secrets..." >> "$REPORT"
echo "" >> "$REPORT"

# Scan for common secret patterns
cd "$WORKSPACE" || exit 1

# API keys and tokens
grep -rn --include="*.js" --include="*.ts" --include="*.json" --include="*.env" --include="*.yaml" --include="*.yml" --include="*.conf" --include="*.config" \
    -E "(API_KEY|SECRET|PASSWORD|TOKEN|PRIVATE_KEY|AUTH|CREDENTIAL).*=.*['\"][a-zA-Z0-9_-]{20,}" . 2>/dev/null | \
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        linenum=$(echo "$line" | cut -d: -f2)
        content=$(echo "$line" | cut -d: -f3-)
        log_issue "Potential hardcoded secret" "$file:$linenum" "$content"
    done

# OpenAI API keys (sk-...)
grep -rn --include="*.js" --include="*.ts" --include="*.json" --include="*.env" \
    -E "sk-[a-zA-Z0-9]{48}" . 2>/dev/null | \
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        linenum=$(echo "$line" | cut -d: -f2)
        log_issue "OpenAI API key detected" "$file:$linenum" "Pattern: sk-..."
    done

# Telegram bot tokens
grep -rn --include="*.js" --include="*.ts" --include="*.json" --include="*.env" \
    -E "[0-9]{8,10}:[a-zA-Z0-9_-]{35}" . 2>/dev/null | \
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        linenum=$(echo "$line" | cut -d: -f2)
        log_issue "Telegram bot token detected" "$file:$linenum" "Pattern: NNNNNNN:XXXXX..."
    done

# AWS keys
grep -rn --include="*.js" --include="*.ts" --include="*.json" --include="*.env" \
    -E "AKIA[0-9A-Z]{16}" . 2>/dev/null | \
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        linenum=$(echo "$line" | cut -d: -f2)
        log_issue "AWS Access Key detected" "$file:$linenum" "Pattern: AKIA..."
    done

echo "## 2. Checking .gitignore Coverage..." >> "$REPORT"
echo "" >> "$REPORT"

# Check for .env files not in .gitignore
if [ -f .gitignore ]; then
    find . -name ".env*" -type f 2>/dev/null | while read -r envfile; do
        if ! grep -q "\.env" .gitignore 2>/dev/null; then
            log_issue ".env file not in .gitignore" "$envfile" "Could be committed accidentally"
        fi
    done
else
    log_issue "No .gitignore file found" "$WORKSPACE" "Repository has no .gitignore protection"
fi

echo "## 3. Scanning Git History..." >> "$REPORT"
echo "" >> "$REPORT"

# Check if we're in a git repo
if [ -d .git ]; then
    # Scan recent commits for accidental secret commits (last 100)
    git log --all --pretty=format: --name-only --diff-filter=A | sort -u | \
        grep -E "\.(env|key|pem|p12|pfx)$" 2>/dev/null | head -20 | \
        while IFS= read -r file; do
            if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
                log_issue "Sensitive file in git history" "$file" "File was committed (may be deleted now)"
            fi
        done
else
    echo "Not a git repository - skipping history scan" >> "$REPORT"
    echo "" >> "$REPORT"
fi

echo "## 4. Network Exposure Check..." >> "$REPORT"
echo "" >> "$REPORT"

# Check for listening ports
lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | tail -n +2 | \
    awk '{print $1, $9}' | sort -u | \
    while read -r proc port; do
        if [[ "$port" =~ :[0-9]+ ]]; then
            port_num=$(echo "$port" | cut -d: -f2)
            # Flag non-standard high-risk ports
            if [ "$port_num" -lt 1024 ] || [ "$port_num" -eq 3306 ] || [ "$port_num" -eq 5432 ] || [ "$port_num" -eq 27017 ]; then
                log_issue "Sensitive port exposed" "$proc on $port" "Database or privileged port listening"
            fi
        fi
    done

echo "## 5. Summary" >> "$REPORT"
echo "" >> "$REPORT"
echo "**Total Issues Found:** $ISSUES_FOUND" >> "$REPORT"
echo "" >> "$REPORT"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ **No security issues detected!**" >> "$REPORT"
else
    echo "⚠️ **Action required:** Review and remediate issues above." >> "$REPORT"
    echo "" >> "$REPORT"
    echo "### Recommended Actions:" >> "$REPORT"
    echo "1. Move hardcoded secrets to 1Password vault" >> "$REPORT"
    echo "2. Use \`op run\` to inject secrets at runtime" >> "$REPORT"
    echo "3. Update .gitignore to exclude sensitive files" >> "$REPORT"
    echo "4. Consider using \`git-secrets\` or BFG to clean git history" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "---" >> "$REPORT"
echo "Scan completed at $(date)" >> "$REPORT"

# Return exit code based on issues found
exit $ISSUES_FOUND
