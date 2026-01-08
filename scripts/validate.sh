#!/bin/bash
set -euo pipefail

# Validation script for n-agent
# Runs all checks before commit/deploy
# Usage: ./scripts/validate.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}n-agent Pre-Commit Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd agent || { echo -e "${RED}ERROR: agent/ directory not found${NC}"; exit 1; }

# Check 1: Dependencies
echo -e "${BLUE}[1/4] Checking dependencies...${NC}"
if ! uv sync --quiet; then
    echo -e "${RED}ERROR: Failed to sync dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}OK Dependencies synced${NC}"
echo ""

# Check 2: Tests
echo -e "${BLUE}[2/4] Running tests...${NC}"
if ! uv run pytest tests/ -v --tb=short; then
    echo -e "${RED}ERROR: Tests failed${NC}"
    exit 1
fi
echo -e "${GREEN}OK All tests passed${NC}"
echo ""

# Check 3: Linter
echo -e "${BLUE}[3/4] Running linter...${NC}"
if ! uv run ruff check src/; then
    echo -e "${YELLOW}WARNING: Linter issues found${NC}"
    echo -e "${YELLOW}Run: uv run ruff check src/ --fix${NC}"
    # Non-blocking
fi
echo -e "${GREEN}OK Linter check complete${NC}"
echo ""

# Check 4: Format check
echo -e "${BLUE}[4/4] Checking code format...${NC}"
if ! uv run ruff format src/ --check; then
    echo -e "${YELLOW}WARNING: Code formatting issues found${NC}"
    echo -e "${YELLOW}Run: uv run ruff format src/${NC}"
    # Non-blocking
fi
echo -e "${GREEN}OK Format check complete${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SUCCESS All checks passed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Ready to commit and deploy${NC}"
