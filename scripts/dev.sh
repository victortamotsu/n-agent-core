#!/bin/bash
set -euo pipefail

# Development server script for n-agent
# Starts agentcore dev server with Memory configured
# Usage: ./scripts/dev.sh

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}n-agent Development Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd agent || { echo -e "${RED}ERROR: agent/ directory not found${NC}"; exit 1; }

# Check if dependencies are installed
if [[ ! -d .venv ]]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    uv sync
    echo ""
fi

# Configure Memory
export BEDROCK_AGENTCORE_MEMORY_ID="nAgentMemory-jXyHuA6yrO"
echo -e "${GREEN}Memory ID: $BEDROCK_AGENTCORE_MEMORY_ID${NC}"
echo ""

# Check if server is already running
if lsof -i :8080 &>/dev/null; then
    echo -e "${YELLOW}WARNING: Port 8080 is already in use${NC}"
    echo -e "${YELLOW}Kill existing process? (y/n)${NC}"
    read -r answer
    if [[ "$answer" == "y" ]]; then
        lsof -ti :8080 | xargs kill -9 || true
        echo -e "${GREEN}Process killed${NC}"
        sleep 2
    else
        echo -e "${YELLOW}Exiting...${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Starting development server...${NC}"
echo -e "${GREEN}Server will be available at:${NC}"
echo "  • http://localhost:8080/invocations"
echo ""
echo -e "${BLUE}Test with:${NC}"
echo '  curl -X POST http://localhost:8080/invocations \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"prompt": "Hello!"}'"'"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Start server (foreground)
uv run agentcore dev
