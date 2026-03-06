#!/bin/bash
# Hourly Health Check - Ensures systems are still working

LOG=~/clawd/logs/health-check.log
HOUR=$(date +%H)

# Only log every 3 hours to save space
if [ $((HOUR % 3)) -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M') - Health check" >> $LOG
    
    # Quick checks
    python3 -c "import imaplib; m=imaplib.IMAP4_SSL('imap.gmail.com'); m.login('tommieseals7700@gmail.com','pxtafuqxzjfegimj')" 2>/dev/null && echo "  Email: ✅" >> $LOG || echo "  Email: ❌" >> $LOG
    
    ssh -o ConnectTimeout=3 dell 'echo 1' 2>/dev/null >/dev/null && echo "  Dell: ✅" >> $LOG || echo "  Dell: ❌" >> $LOG
fi
