#!/bin/bash
# Test the security alert system by creating a fake issue

echo "Creating test file with exposed secret..."
mkdir -p /tmp/security-test
echo 'const API_KEY = "sk-1234567890abcdefghijklmnopqrstuvwxyz123456"' > /tmp/security-test/test.js

echo "Running security audit on test directory..."
cd /tmp/security-test

# Run a quick scan
grep -rn -E "sk-[a-zA-Z0-9]{48}" . 2>/dev/null && echo "✅ Test secret detected!"

echo ""
echo "Cleaning up test..."
rm -rf /tmp/security-test

echo ""
echo "To simulate a real alert:"
echo "1. Add an API key to a file in /Users/tommie/clawd/"
echo "2. Run: /Users/tommie/clawd/scripts/security-audit-notify.sh"
echo "3. Check: /Users/tommie/clawd/scripts/check-security-alerts.sh"
