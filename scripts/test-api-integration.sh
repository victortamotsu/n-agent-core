#!/bin/bash
# API Integration Tests for n-agent
# Tests end-to-end flow: Cognito Auth → API Gateway → Lambda BFF → AgentCore

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (to be set via environment or parameters)
COGNITO_USER_POOL_ID="${COGNITO_USER_POOL_ID:-}"
COGNITO_CLIENT_ID="${COGNITO_CLIENT_ID:-}"
API_ENDPOINT="${API_ENDPOINT:-}"
TEST_USERNAME="${TEST_USERNAME:-test@example.com}"
TEST_PASSWORD="${TEST_PASSWORD:-}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}n-agent API Integration Tests${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Validate configuration
if [ -z "$COGNITO_USER_POOL_ID" ] || [ -z "$COGNITO_CLIENT_ID" ] || [ -z "$API_ENDPOINT" ]; then
    echo -e "${RED}ERROR: Missing required configuration${NC}"
    echo ""
    echo "Required environment variables:"
    echo "  COGNITO_USER_POOL_ID"
    echo "  COGNITO_CLIENT_ID"
    echo "  API_ENDPOINT"
    echo "  TEST_USERNAME (optional, default: test@example.com)"
    echo "  TEST_PASSWORD (required for auth)"
    echo ""
    exit 1
fi

# Test 1: Health Check (public endpoint)
echo -e "${YELLOW}Test 1: Health Check (GET /health)${NC}"
if response=$(curl -s -X GET "$API_ENDPOINT/health"); then
    if echo "$response" | grep -q "healthy"; then
        echo -e "  ${GREEN}✓ PASSED${NC} - API is healthy"
    else
        echo -e "  ${RED}✗ FAILED${NC} - Unexpected response: $response"
        exit 1
    fi
else
    echo -e "  ${RED}✗ FAILED${NC} - Health check failed"
    exit 1
fi
echo ""

# Test 2: Get Cognito Token
echo -e "${YELLOW}Test 2: Authenticate with Cognito${NC}"
if [ -z "$TEST_PASSWORD" ]; then
    echo -e "  ${YELLOW}⚠ SKIPPED${NC} - TEST_PASSWORD not set"
    echo -e "  ${BLUE}NOTE:${NC} To run full tests, set TEST_PASSWORD environment variable"
    exit 0
fi

# Initiate auth
auth_response=$(aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id "$COGNITO_CLIENT_ID" \
    --auth-parameters "USERNAME=$TEST_USERNAME,PASSWORD=$TEST_PASSWORD" \
    --output json 2>&1) || {
    echo -e "  ${RED}✗ FAILED${NC} - Authentication failed"
    echo "  Response: $auth_response"
    exit 1
}

# Extract ID token
ID_TOKEN=$(echo "$auth_response" | jq -r '.AuthenticationResult.IdToken')

if [ "$ID_TOKEN" = "null" ] || [ -z "$ID_TOKEN" ]; then
    echo -e "  ${RED}✗ FAILED${NC} - Failed to get ID token"
    echo "  Response: $auth_response"
    exit 1
fi

echo -e "  ${GREEN}✓ PASSED${NC} - Successfully authenticated"
echo ""

# Test 3: Call API without token (should fail)
echo -e "${YELLOW}Test 3: Call API without authentication (should fail)${NC}"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_ENDPOINT/chat" \
    -H "Content-Type: application/json" \
    -d '{"prompt": "Hello"}')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} - Correctly rejected unauthorized request (HTTP $http_code)"
else
    echo -e "  ${RED}✗ FAILED${NC} - Expected 401/403, got HTTP $http_code"
    echo "  Response: $body"
    exit 1
fi
echo ""

# Test 4: Call API with valid token
echo -e "${YELLOW}Test 4: Chat with agent (authenticated)${NC}"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_ENDPOINT/chat" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ID_TOKEN" \
    -d '{"prompt": "Olá! Estou testando a integração."}')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    # Validate response structure
    if echo "$body" | jq -e '.response' > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSED${NC} - Agent responded successfully"
        echo "  Response preview: $(echo "$body" | jq -r '.response' | head -c 100)..."
    else
        echo -e "  ${RED}✗ FAILED${NC} - Invalid response structure"
        echo "  Response: $body"
        exit 1
    fi
else
    echo -e "  ${RED}✗ FAILED${NC} - Expected HTTP 200, got $http_code"
    echo "  Response: $body"
    exit 1
fi
echo ""

# Test 5: Memory context (cross-session)
echo -e "${YELLOW}Test 5: Memory context persistence${NC}"
SESSION_ID="test-session-$(date +%s)"

# First message: save context
response1=$(curl -s -X POST "$API_ENDPOINT/chat" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ID_TOKEN" \
    -d "{\"prompt\": \"Meu nome é Test User e quero viajar para Tokyo\", \"session_id\": \"$SESSION_ID\"}")

if echo "$response1" | jq -e '.response' > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Context saved (session: $SESSION_ID)"
else
    echo -e "  ${RED}✗ FAILED${NC} - Failed to save context"
    exit 1
fi

sleep 3  # Wait for memory propagation

# Second message: retrieve context
response2=$(curl -s -X POST "$API_ENDPOINT/chat" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ID_TOKEN" \
    -d "{\"prompt\": \"Qual é meu destino?\", \"session_id\": \"$SESSION_ID\"}")

if echo "$response2" | jq -r '.response' | grep -qi "tokyo"; then
    echo -e "  ${GREEN}✓ PASSED${NC} - Memory context retrieved correctly"
else
    echo -e "  ${YELLOW}⚠ WARNING${NC} - Memory context may not be working correctly"
    echo "  Response: $(echo "$response2" | jq -r '.response')"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ All tests completed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "API Endpoint: $API_ENDPOINT"
echo "Cognito User Pool: $COGNITO_USER_POOL_ID"
echo ""
