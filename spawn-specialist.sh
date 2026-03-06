#!/bin/bash
# Specialist Agent Swarm Spawner
# Usage: ./spawn-specialist.sh <agent_name> [task]
# Example: ./spawn-specialist.sh codegen "Create Python script to parse logs"

set -e

AGENT_NAME="$1"
TASK="$2"

# Agent base directory
AGENTS_DIR="$HOME/clawd/agents"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function usage() {
    echo "Usage: $0 <agent_name> <task>"
    echo ""
    echo "Available specialists:"
    echo "  router    - Task routing and orchestration"
    echo "  codegen   - Code generation (Qwen Coder 32B)"
    echo "  debugger  - Debugging and troubleshooting (Kimi K2.5)"
    echo "  research  - Deep research and analysis (Llama 90B)"
    echo "  vision    - Image analysis (Llama 11B Vision)"
    echo "  writer    - Documentation and content creation"
    echo "  devops    - Infrastructure and deployment"
    echo ""
    echo "Example:"
    echo "  $0 codegen 'Create Python script to parse JSON logs'"
    echo "  $0 debugger 'Investigate why service X is failing'"
    exit 1
}

if [ -z "$AGENT_NAME" ]; then
    usage
fi

# Validate agent exists
AGENT_DIR="${AGENTS_DIR}/${AGENT_NAME}"
CONFIG_FILE="${AGENT_DIR}/config.json"
ROLE_FILE="${AGENT_DIR}/ROLE.md"

if [ ! -d "$AGENT_DIR" ]; then
    echo -e "${RED}Error: Agent '${AGENT_NAME}' not found${NC}"
    echo "Directory does not exist: ${AGENT_DIR}"
    usage
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found: ${CONFIG_FILE}${NC}"
    exit 1
fi

if [ ! -f "$ROLE_FILE" ]; then
    echo -e "${RED}Error: ROLE.md file not found: ${ROLE_FILE}${NC}"
    exit 1
fi

# Load config
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq not found, using basic parsing${NC}"
    MODEL=$(grep '"model"' "$CONFIG_FILE" | sed 's/.*: "\(.*\)".*/\1/')
    DESCRIPTION=$(grep '"description"' "$CONFIG_FILE" | sed 's/.*: "\(.*\)".*/\1/')
    THINKING=$(grep '"thinking"' "$CONFIG_FILE" | sed 's/.*: "\(.*\)".*/\1/' || echo "low")
    LLM_GATEWAY=$(grep '"llm_gateway"' "$CONFIG_FILE" | sed 's/.*: \(.*\),*/\1/' || echo "false")
else
    MODEL=$(jq -r '.model' "$CONFIG_FILE")
    DESCRIPTION=$(jq -r '.description' "$CONFIG_FILE")
    THINKING=$(jq -r '.thinking // "low"' "$CONFIG_FILE")
    LLM_GATEWAY=$(jq -r '.llm_gateway // false' "$CONFIG_FILE")
fi

# Generate session label
TIMESTAMP=$(date +%s)
LABEL="specialist-${AGENT_NAME}-${TIMESTAMP}"

echo -e "${BLUE}🚢 Spawning Specialist Agent${NC}"
echo -e "${GREEN}Agent:${NC}        ${AGENT_NAME} (${DESCRIPTION})"
echo -e "${GREEN}Model:${NC}        ${MODEL}"
echo -e "${GREEN}Thinking:${NC}     ${THINKING}"
echo -e "${GREEN}LLM Gateway:${NC}  ${LLM_GATEWAY}"
echo -e "${GREEN}Label:${NC}        ${LABEL}"
echo ""

# Build task prompt
TASK_PROMPT="You are a **${AGENT_NAME} specialist agent** in the swarm.

## Your Configuration
- Agent: ${AGENT_NAME}
- Model: ${MODEL}
- Description: ${DESCRIPTION}

## Your Task
${TASK}

## CRITICAL - Read These Files First
1. **Read ~/clawd/agents/${AGENT_NAME}/ROLE.md** - Your specialist role and guidelines
2. **Read ~/clawd/AGENTS.md** - General agent protocols (if needed for context)
3. **Read ~/clawd/TOOLS.md** - Available tools reference

## Rules
- You are a SPECIALIST - stay focused on your domain
- Complete the task assigned to you
- Report results clearly when done
- You are ephemeral - no heartbeats, no side quests
- If you need another specialist, coordinate through your requester

## Session Info
- Label: ${LABEL}
- Requester: Main agent or coordinator
- Your role: ${AGENT_NAME} specialist

## LLM Gateway
"

# Add LLM Gateway instructions if applicable
if [ "$LLM_GATEWAY" = "true" ]; then
    TASK_PROMPT+="
Your model (${MODEL}) is accessed via LLM Gateway at ~/dta/gateway/

**DO NOT** call the gateway directly - your model is already configured.
Your responses will automatically use ${MODEL} via the gateway.
"
fi

TASK_PROMPT+="

Now read your ROLE.md and begin your specialized work!"

# Check for sessions_spawn command
if command -v sessions_spawn &> /dev/null; then
    echo -e "${GREEN}✅ Spawning via sessions_spawn...${NC}"
    sessions_spawn --label="${LABEL}" --task="${TASK_PROMPT}"
    SPAWN_STATUS=$?
    
    if [ $SPAWN_STATUS -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Agent spawned successfully${NC}"
        echo -e "${BLUE}📊 Monitor:${NC} http://100.88.105.106:8080/swarm-monitor.html"
        echo -e "${BLUE}🔍 Status:${NC} sessions_list | grep ${LABEL}"
        echo ""
        echo -e "${YELLOW}Session key: ${LABEL}${NC}"
        exit 0
    else
        echo -e "${RED}❌ Spawn failed with status ${SPAWN_STATUS}${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  sessions_spawn command not found${NC}"
    echo ""
    echo "Manual spawn instructions:"
    echo "1. Run this in Telegram or Clawdbot:"
    echo ""
    echo "/spawn ${LABEL}"
    echo ""
    echo "2. Paste this task:"
    echo "---"
    echo "${TASK_PROMPT}"
    echo "---"
    echo ""
    echo -e "${BLUE}📊 Monitor:${NC} http://100.88.105.106:8080/swarm-monitor.html"
fi
