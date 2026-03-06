#!/bin/bash
# Specialist Swarm System Demo
# Shows how to spawn and coordinate specialist agents

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      SPECIALIST SWARM SYSTEM - DEMO                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}This demo shows how to spawn specialist agents for different tasks.${NC}"
echo ""

echo -e "${YELLOW}Available Specialists:${NC}"
echo "  1. router    - Task routing and orchestration"
echo "  2. codegen   - Code generation (Qwen Coder 32B)"
echo "  3. debugger  - Debugging (Kimi K2.5 with reasoning)"
echo "  4. research  - Deep research (Llama 405B)"
echo "  5. vision    - Image analysis (Llama 11B Vision)"
echo "  6. writer    - Documentation creation"
echo "  7. devops    - Infrastructure & deployment"
echo ""

echo -e "${YELLOW}Example Commands:${NC}"
echo ""

echo -e "${BLUE}# Spawn code generation specialist${NC}"
echo "~/clawd/scripts/spawn-specialist.sh codegen \"Create Python function to parse JSON\""
echo ""

echo -e "${BLUE}# Spawn debugger specialist${NC}"
echo "~/clawd/scripts/spawn-specialist.sh debugger \"Investigate API 500 errors\""
echo ""

echo -e "${BLUE}# Spawn research specialist${NC}"
echo "~/clawd/scripts/spawn-specialist.sh research \"Compare Python vs Go for web APIs\""
echo ""

echo -e "${BLUE}# Spawn vision specialist${NC}"
echo "~/clawd/scripts/spawn-specialist.sh vision \"Analyze error in screenshot.png\""
echo ""

echo -e "${YELLOW}Direct Model Access (via LLM Gateway):${NC}"
echo ""

echo -e "${BLUE}# Quick code generation${NC}"
echo "~/dta/gateway/codegen \"write bubble sort in python\""
echo ""

echo -e "${BLUE}# Deep document analysis${NC}"
echo "~/dta/gateway/deep-analyze \"summarize this 50-page report\""
echo ""

echo -e "${BLUE}# Fast image analysis${NC}"
echo "~/dta/gateway/quick-vision --image screenshot.png \"what's the error?\""
echo ""

echo -e "${YELLOW}Monitoring:${NC}"
echo "  Dashboard: http://100.88.105.106:8080/swarm-monitor.html"
echo "  CLI: sessions_list | grep specialist-"
echo ""

echo -e "${GREEN}✅ System is ready for deployment!${NC}"
echo ""
echo "Run a test command? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}Testing with simple query...${NC}"
    ~/dta/gateway/ask "What is 2+2?"
    echo ""
    echo -e "${GREEN}✅ Test successful!${NC}"
fi
