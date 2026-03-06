#!/bin/bash
# Ultra-Fast Financial Monitor - Non-blocking

echo "💰 Financial Check @ $(date '+%H:%M:%S')"

# Quick SSH test with 3-second timeout
if ssh -o ConnectTimeout=3 -o ServerAliveInterval=1 dell 'echo 1' 2>/dev/null | grep -q "1"; then
    echo "  ✅ Dell: Online"
    
    # --- VAULT STATUS CHECK (background, non-blocking) ---
    {
        VAULT_STATUS=$(ssh -o ConnectTimeout=5 dell 'cd C:\Users\tommi\clawd\project-vault 2>nul && python vault.py status 2>nul' 2>/dev/null | grep "Total Equity" | head -1)
        if [ -n "$VAULT_STATUS" ]; then
            echo "  📊 $VAULT_STATUS" >> ~/clawd/logs/vault-quick.log
            echo "$(date '+%Y-%m-%d %H:%M:%S') | $VAULT_STATUS" >> ~/clawd/logs/vault-history.log
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') | ⚠️  Vault: No response" >> ~/clawd/logs/vault-history.log
        fi
    } &
    
    # --- TERMINATORBOT STATUS CHECK (quick process check) ---
    {
        # Check if TerminatorBot directory exists and get last modified time
        TERM_STATUS=$(ssh -o ConnectTimeout=5 dell 'if exist "C:\Users\tommi\clawd\TerminatorBot" (echo INSTALLED) else (echo MISSING)' 2>/dev/null | tr -d '\r\n')
        
        # Check if Python processes are running
        PYTHON_RUNNING=$(ssh -o ConnectTimeout=5 dell 'tasklist 2>nul | findstr /i python' 2>/dev/null)
        
        if [ "$TERM_STATUS" = "INSTALLED" ]; then
            if [ -n "$PYTHON_RUNNING" ]; then
                PYTHON_COUNT=$(echo "$PYTHON_RUNNING" | wc -l | tr -d ' ')
                echo "$(date '+%Y-%m-%d %H:%M:%S') | ✅ TerminatorBot: Installed, $PYTHON_COUNT Python processes running" >> ~/clawd/logs/terminator-quick.log
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') | ⚠️  TerminatorBot: Installed, but not actively running" >> ~/clawd/logs/terminator-quick.log
            fi
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') | ❌ TerminatorBot: Not found" >> ~/clawd/logs/terminator-quick.log
        fi
    } &
    
    echo "  📊 Vault: Checking (background)"
    echo "  🤖 TerminatorBot: Checking (background)"
else
    echo "  ⚠️  Dell: Cannot connect (will retry)"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ⚠️  Dell offline" >> ~/clawd/logs/vault-history.log
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ⚠️  Dell offline" >> ~/clawd/logs/terminator-quick.log
fi

echo "━━━━━━━━━━━━━━━━━━━━"

# Quick status summary from recent logs (non-blocking)
{
    sleep 2  # Give background jobs time to complete
    
    echo ""
    echo "📋 Latest Status:"
    
    # Show last Vault check
    if [ -f ~/clawd/logs/vault-quick.log ]; then
        LAST_VAULT=$(tail -1 ~/clawd/logs/vault-quick.log 2>/dev/null)
        if [ -n "$LAST_VAULT" ]; then
            echo "  $LAST_VAULT"
        fi
    fi
    
    # Show last TerminatorBot check
    if [ -f ~/clawd/logs/terminator-quick.log ]; then
        LAST_TERM=$(tail -1 ~/clawd/logs/terminator-quick.log 2>/dev/null | cut -d'|' -f2-)
        if [ -n "$LAST_TERM" ]; then
            echo "  🤖$LAST_TERM"
        fi
    fi
    
} &

# Don't wait for background jobs
exit 0
