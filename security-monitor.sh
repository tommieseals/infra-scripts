#!/bin/bash
# Security Monitoring Script for Clawdbot
# Created: 2026-02-11
# Purpose: Daily security audit and monitoring

set -e

echo "🔒 Clawdbot Security Monitor"
echo "============================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Run Clawdbot security audit
echo "📊 Running Clawdbot security audit..."
echo ""
AUDIT_OUTPUT=$(clawdbot security audit 2>&1)
echo "$AUDIT_OUTPUT"
echo ""

# Extract summary
CRITICAL=$(echo "$AUDIT_OUTPUT" | grep "Summary:" | sed 's/.*: \([0-9]*\) critical.*/\1/')
WARNINGS=$(echo "$AUDIT_OUTPUT" | grep "Summary:" | sed 's/.*critical · \([0-9]*\) warn.*/\1/')

# Check for critical issues
if [ "$CRITICAL" -gt 0 ]; then
    echo -e "${RED}⚠️  CRITICAL: $CRITICAL critical security issues found!${NC}"
    echo "Run: clawdbot security audit --deep"
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNING: $WARNINGS security warnings${NC}"
fi

# Scan for exposed secrets in workspace
echo "🔍 Scanning for exposed secrets..."
WORKSPACE="/Users/tommie/clawd"
SECRET_PATTERNS="sk-ant|sk-svcacct|AKIA|ghp_|gho_|github_pat"

FOUND_SECRETS=$(cd "$WORKSPACE" && grep -r -E "$SECRET_PATTERNS" . \
    --include="*.md" --include="*.json" --include="*.js" --include="*.py" \
    --exclude-dir=node_modules --exclude-dir=.git \
    2>/dev/null | grep -v "REDACTED" | grep -v "example" | grep -v "\.\.\." || true)

if [ -n "$FOUND_SECRETS" ]; then
    echo -e "${RED}⚠️  EXPOSED SECRETS FOUND!${NC}"
    echo "$FOUND_SECRETS"
    echo ""
    echo "Action required: Redact or remove these secrets!"
    exit 1
else
    echo -e "${GREEN}✅ No exposed secrets found${NC}"
fi

# Check gateway configuration
echo ""
echo "🔧 Checking gateway configuration..."

GROUP_POLICY=$(cat ~/.clawdbot/clawdbot.json | jq -r '.channels.telegram.groupPolicy // "not set"')
if [ "$GROUP_POLICY" != "allowlist" ]; then
    echo -e "${RED}⚠️  Group policy is NOT set to allowlist!${NC}"
    echo "Current: $GROUP_POLICY"
    echo "Fix: Set channels.telegram.groupPolicy = 'allowlist'"
    exit 1
else
    echo -e "${GREEN}✅ Group policy: allowlist (secure)${NC}"
fi

# Check for gateway authentication
AUTH_MODE=$(cat ~/.clawdbot/clawdbot.json | jq -r '.gateway.auth.mode // "not set"')
if [ "$AUTH_MODE" != "token" ]; then
    echo -e "${YELLOW}⚠️  Gateway auth mode: $AUTH_MODE${NC}"
else
    echo -e "${GREEN}✅ Gateway auth: token-based${NC}"
fi

# Check bind address
BIND=$(cat ~/.clawdbot/clawdbot.json | jq -r '.gateway.bind // "not set"')
if [ "$BIND" != "loopback" ]; then
    echo -e "${YELLOW}⚠️  Gateway NOT bound to loopback!${NC}"
    echo "Current: $BIND"
else
    echo -e "${GREEN}✅ Gateway bound to loopback (local only)${NC}"
fi

echo ""
echo "📈 System Status:"
echo "- Connected channels: $(clawdbot status --json 2>/dev/null | jq -r '.channels | length')"
echo "- Active sessions: $(clawdbot status --json 2>/dev/null | jq -r '.sessions | length')"
echo ""

if [ "$CRITICAL" -eq 0 ]; then
    echo -e "${GREEN}🎉 Security audit PASSED!${NC}"
    exit 0
fi
