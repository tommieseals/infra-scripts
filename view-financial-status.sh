#!/bin/bash
# View Financial Monitoring Status

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💰 FINANCIAL MONITORING STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vault Status
echo "📊 VAULT (Project Vault - Trading)"
if [ -f ~/clawd/logs/vault-history.log ]; then
    echo "  Latest: $(tail -1 ~/clawd/logs/vault-history.log)"
    echo "  History: $(wc -l ~/clawd/logs/vault-history.log | awk '{print $1}') checks logged"
else
    echo "  ⚠️  No logs found"
fi

echo ""

# TerminatorBot Status
echo "🤖 TERMINATORBOT (Prediction Markets)"
if [ -f ~/clawd/logs/terminator-quick.log ]; then
    echo "  Latest: $(tail -1 ~/clawd/logs/terminator-quick.log)"
    echo "  History: $(wc -l ~/clawd/logs/terminator-quick.log | awk '{print $1}') checks logged"
else
    echo "  ⚠️  No logs found"
fi

echo ""

# Summary
echo "📈 SUMMARY"
if [ -f ~/clawd/logs/vault-quick.log ]; then
    VAULT_VALUE=$(tail -1 ~/clawd/logs/vault-quick.log | grep -o '\$[0-9,]*\.[0-9]*')
    if [ -n "$VAULT_VALUE" ]; then
        echo "  Total Portfolio Value: $VAULT_VALUE"
    fi
fi

# Check how long ago last check was
if [ -f ~/clawd/logs/vault-history.log ]; then
    LAST_CHECK=$(tail -1 ~/clawd/logs/vault-history.log | cut -d'|' -f1 | xargs)
    echo "  Last Check: $LAST_CHECK"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Run: ~/clawd/scripts/auto-financial-monitor.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
