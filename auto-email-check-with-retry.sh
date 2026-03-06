#!/bin/bash
# Email check with automatic retry on failure
# Fixed 2026-03-02: Updated to match new output format

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    OUTPUT=$(bash ~/clawd/scripts/auto-email-check.sh 2>&1)
    
    # Check for success (either recruiter emails or "No new")
    if echo "$OUTPUT" | grep -qE "RECRUITER EMAILS|No new|No urgent"; then
        echo "$OUTPUT"  # Print output to log
        exit 0  # Success
    fi
    
    ((RETRY_COUNT++))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        sleep 30  # Wait 30 seconds before retry
    fi
done

echo "❌ Email check failed after $MAX_RETRIES attempts ($(date))" >> ~/clawd/logs/email-failures.log
exit 1
