#!/bin/bash
# PROJECT VAULT - Individual Test Runner
# Usage: ./vault-run-test.sh [test_number] [test_name]

TEST_NUM=$1
TEST_NAME=$2
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
LOG_DIR="$HOME/clawd/memory/vault-tests"

mkdir -p $LOG_DIR

echo "=================================================================="
echo "🚀 PROJECT VAULT - TEST RUN #$TEST_NUM"
echo "Test: $TEST_NAME"
echo "Time: $TIMESTAMP"
echo "=================================================================="

# Run the full strategy suite on Dell
echo "📊 Executing full strategy scan..."
ssh dell "cd C:\\Users\\tommi\\clawd\\project-vault && python run_all_strategies.py 2>&1" > "$LOG_DIR/test-$TEST_NUM-output.log" 2>&1

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test Run #$TEST_NUM COMPLETED SUCCESSFULLY"
else
    echo "❌ Test Run #$TEST_NUM FAILED (Exit code: $EXIT_CODE)"
fi

# Get portfolio status
echo ""
echo "📊 Portfolio Status:"
ssh dell "cd C:\\Users\\tommi\\clawd\\project-vault && python vault.py status 2>&1"

echo ""
echo "📈 Current Positions:"
ssh dell "cd C:\\Users\\tommi\\clawd\\project-vault && python vault.py positions 2>&1"

echo ""
echo "📋 Recent Orders:"
ssh dell "cd C:\\Users\\tommi\\clawd\\project-vault && python vault.py orders 2>&1"

# Save results
cat > "$LOG_DIR/test-$TEST_NUM-summary.txt" << EOF
Test Run #$TEST_NUM - $TEST_NAME
Time: $TIMESTAMP
Exit Code: $EXIT_CODE
Status: $([ $EXIT_CODE -eq 0 ] && echo "PASS" || echo "FAIL")
EOF

echo ""
echo "=================================================================="
echo "📝 Results saved to: $LOG_DIR/test-$TEST_NUM-summary.txt"
echo "=================================================================="

exit $EXIT_CODE
