#!/bin/bash
# Production Test Script for n-agent
# Tests agent functionality in deployed environment (local or AWS)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}n-agent Production Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Detect environment
if [ -n "${CI:-}" ]; then
    ENVIRONMENT="GitHub Actions"
    TEST_MODE="production"
else
    ENVIRONMENT="Local"
    TEST_MODE="${1:-production}"  # Default to production, allow "local" or "dev"
fi

echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
echo -e "${BLUE}Test Mode:${NC} $TEST_MODE"
echo ""

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -e "${YELLOW}Test $TESTS_TOTAL:${NC} $test_name"
    
    # Run command and capture output
    if output=$(eval "$test_command" 2>&1); then
        # Check if output matches expected pattern
        if echo "$output" | grep -qi "$expected_pattern"; then
            echo -e "  ${GREEN}✓ PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "  ${RED}✗ FAILED${NC} - Expected pattern not found: $expected_pattern"
            echo -e "  ${YELLOW}Output:${NC} ${output:0:200}..."
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "  ${RED}✗ FAILED${NC} - Command failed"
        echo -e "  ${YELLOW}Output:${NC} ${output:0:200}..."
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Generate unique session ID
SESSION_ID="test-$(date +%s)-$$"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Running Tests (Session: $SESSION_ID)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$TEST_MODE" = "local" ] || [ "$TEST_MODE" = "dev" ]; then
    # Local/Dev mode tests (agentcore dev)
    echo -e "${YELLOW}Testing against local dev server...${NC}"
    echo ""
    
    # Test 1: Basic invoke
    run_test \
        "Basic greeting" \
        "curl -s -X POST http://localhost:8080/invocations -H 'Content-Type: application/json' -d '{\"prompt\": \"Olá!\"}'" \
        "response"
    
    # Test 2: Travel query
    run_test \
        "Travel query (router test)" \
        "curl -s -X POST http://localhost:8080/invocations -H 'Content-Type: application/json' -d '{\"prompt\": \"Quero viajar para Paris em maio\"}'" \
        "Paris"
    
    # Test 3: Memory context
    run_test \
        "Memory context save" \
        "curl -s -X POST http://localhost:8080/invocations -H 'Content-Type: application/json' -d '{\"prompt\": \"Meu nome é Victor\", \"session_id\": \"$SESSION_ID\"}'" \
        "response"
    
    sleep 2  # Wait for memory propagation
    
    run_test \
        "Memory context retrieval" \
        "curl -s -X POST http://localhost:8080/invocations -H 'Content-Type: application/json' -d '{\"prompt\": \"Qual é meu nome?\", \"session_id\": \"$SESSION_ID\"}'" \
        "Victor"

else
    # Production mode tests (agentcore invoke)
    echo -e "${YELLOW}Testing against production (AgentCore Runtime)...${NC}"
    echo ""
    
    cd "$(dirname "$0")/../agent" || exit 1
    
    # Test 1: Basic invoke
    run_test \
        "Basic greeting" \
        "agentcore invoke '{\"prompt\": \"Olá!\"}' --session-id \"$SESSION_ID\" 2>&1" \
        "n-agent"
    
    # Test 2: Travel query
    run_test \
        "Travel query (router test)" \
        "agentcore invoke '{\"prompt\": \"Quero viajar para Roma\"}' --session-id \"$SESSION_ID-2\" 2>&1" \
        "Roma"
    
    # Test 3: Memory context save
    MEMORY_SESSION="memory-test-$SESSION_ID"
    run_test \
        "Memory context save" \
        "agentcore invoke '{\"prompt\": \"Meu nome é Victor e vou para Tokyo\"}' --session-id \"$MEMORY_SESSION\" 2>&1" \
        "Tokyo"
    
    sleep 3  # Wait for memory propagation in AWS
    
    # Test 4: Memory context retrieval
    run_test \
        "Memory context retrieval" \
        "agentcore invoke '{\"prompt\": \"Qual meu destino?\"}' --session-id \"$MEMORY_SESSION\" 2>&1" \
        "Tokyo"
    
    # Test 5: Router cost optimization
    run_test \
        "Router classification (trivial -> Nova Lite)" \
        "agentcore invoke '{\"prompt\": \"obrigado\"}' --session-id \"$SESSION_ID-3\" 2>&1" \
        "de nada"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Results${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Total:  $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
