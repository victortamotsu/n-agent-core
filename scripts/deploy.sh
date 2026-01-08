#!/bin/bash
set -euo pipefail

# Deploy script for n-agent AgentCore Runtime
# Validates, tests, and deploys to production
# Usage: ./deploy.sh [--skip-tests]

# Fix encoding for Windows terminals (emoji support)
export PYTHONIOENCODING=utf-8

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}n-agent AgentCore Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse arguments
SKIP_TESTS=false
if [[ "${1:-}" == "--skip-tests" ]]; then
    SKIP_TESTS=true
    echo -e "${YELLOW}WARNING: Skipping tests${NC}"
    echo ""
fi

# Change to agent directory
cd agent || { echo -e "${RED}ERROR: agent/ directory not found${NC}"; exit 1; }

# Step 1: Sync dependencies
echo -e "${BLUE}Step 1: Installing dependencies...${NC}"
if ! uv sync; then
    echo -e "${RED}ERROR: Failed to install dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}OK Dependencies installed${NC}"
echo ""

# Step 2: Generate requirements.txt (no dev dependencies)
echo -e "${BLUE}Step 2: Generating requirements.txt...${NC}"
if ! uv pip compile pyproject.toml --universal > requirements.txt; then
    echo -e "${RED}ERROR: Failed to generate requirements.txt${NC}"
    exit 1
fi
echo -e "${GREEN}OK requirements.txt generated${NC}"
echo ""

# Step 3: Validate requirements (no ruamel-yaml)
echo -e "${BLUE}Step 3: Validating requirements.txt...${NC}"
if grep -qi "ruamel" requirements.txt; then
    echo -e "${RED}ERROR: ruamel-yaml found in requirements.txt!${NC}"
    echo -e "${YELLOW}This will cause deploy failure (no ARM64 wheels)${NC}"
    echo -e "${YELLOW}Move bedrock-agentcore-starter-toolkit to [dependency-groups]${NC}"
    exit 1
fi
echo -e "${GREEN}OK No ruamel-yaml in requirements.txt${NC}"
echo ""

# Step 4: Run tests (unless skipped)
if [[ "$SKIP_TESTS" == false ]]; then
    echo -e "${BLUE}Step 4: Running tests...${NC}"
    if ! uv run pytest tests/ -v; then
        echo -e "${RED}ERROR: Tests failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}OK All tests passed${NC}"
    echo ""
else
    echo -e "${YELLOW}Step 4: Tests skipped${NC}"
    echo ""
fi

# Step 5: Run linter
echo -e "${BLUE}Step 5: Running linter...${NC}"
if ! uv run ruff check src/; then
    echo -e "${YELLOW}WARNING: Linter found issues (non-blocking)${NC}"
    echo -e "${YELLOW}Run: uv run ruff check src/ --fix${NC}"
    echo ""
fi
echo -e "${GREEN}OK Linter check complete${NC}"
echo ""

# Step 6: Check if agentcore CLI is available
echo -e "${BLUE}Step 6: Checking AgentCore CLI...${NC}"
if ! command -v agentcore &>/dev/null; then
    echo -e "${YELLOW}AgentCore CLI not found, installing...${NC}"
    if ! uv tool install bedrock-agentcore-starter-toolkit; then
        echo -e "${RED}ERROR: Failed to install AgentCore CLI${NC}"
        exit 1
    fi
    # Add to PATH temporarily
    export PATH="$HOME/.local/bin:$PATH"
fi
echo -e "${GREEN}OK AgentCore CLI ready${NC}"
echo ""

# Step 7: Deploy to AgentCore Runtime
echo -e "${BLUE}Step 7: Deploying to AgentCore Runtime...${NC}"
echo -e "${YELLOW}This may take 2-3 minutes...${NC}"
echo ""

if agentcore launch; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}SUCCESS Deploy complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Agent ARN:${NC} arn:aws:bedrock-agentcore:us-east-1:944938120078:runtime/nagent-GcrnJb6DU5"
    echo ""
    echo -e "${BLUE}Test the deployment:${NC}"
    echo "  agentcore invoke \"Hello!\" --session-id \"test-\$(uuidgen)\" --user-id \"test-user\""
    echo ""
    echo -e "${BLUE}View logs:${NC}"
    echo "  aws logs tail /aws/bedrock-agentcore/runtimes/nagent-GcrnJb6DU5-DEFAULT --follow"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}ERROR Deploy failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Check logs:${NC}"
    echo "  aws logs tail /aws/bedrock-agentcore/runtimes/nagent-GcrnJb6DU5-DEFAULT --since 10m"
    echo ""
    exit 1
fi
