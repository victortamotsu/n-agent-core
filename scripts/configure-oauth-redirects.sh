#!/bin/bash
# Configure OAuth Redirect URIs for Google and Microsoft
# This script automates the configuration of redirect URIs for OAuth providers

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COGNITO_DOMAIN="n-agent-core-prod.auth.us-east-1.amazoncognito.com"
REDIRECT_URI="https://${COGNITO_DOMAIN}/oauth2/idpresponse"

echo -e "${GREEN}=== n-agent OAuth Redirect URI Configuration ===${NC}\n"
echo -e "Cognito Domain: ${YELLOW}${COGNITO_DOMAIN}${NC}"
echo -e "Required Redirect URI: ${YELLOW}${REDIRECT_URI}${NC}\n"

# Get OAuth credentials from AWS Secrets Manager
echo -e "${GREEN}Fetching OAuth credentials from AWS Secrets Manager...${NC}"
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id n-agent-core-prod-credentials \
  --query SecretString \
  --output text)

GOOGLE_CLIENT_ID=$(echo "$SECRET_JSON" | jq -r '.oauth.google.client_id')
GOOGLE_PROJECT=$(echo "$GOOGLE_CLIENT_ID" | cut -d'-' -f1)
MICROSOFT_CLIENT_ID=$(echo "$SECRET_JSON" | jq -r '.oauth.microsoft.client_id')

echo -e "Google Client ID: ${YELLOW}${GOOGLE_CLIENT_ID}${NC}"
echo -e "Google Project: ${YELLOW}${GOOGLE_PROJECT}${NC}"
echo -e "Microsoft Client ID: ${YELLOW}${MICROSOFT_CLIENT_ID}${NC}\n"

# ==================== GOOGLE CONFIGURATION ====================
echo -e "${GREEN}=== Configuring Google OAuth ===${NC}"

# Check if gcloud is authenticated
if ! gcloud auth print-access-token &>/dev/null; then
  echo -e "${RED}Error: gcloud is not authenticated${NC}"
  echo "Run: gcloud auth login"
  exit 1
fi

# Set the correct project
gcloud config set project "$GOOGLE_PROJECT" --quiet

echo -e "${YELLOW}Manual steps required for Google:${NC}"
echo "1. Open: https://console.cloud.google.com/apis/credentials?project=${GOOGLE_PROJECT}"
echo "2. Click on OAuth 2.0 Client ID: ${GOOGLE_CLIENT_ID}"
echo "3. Under 'Authorized redirect URIs', add:"
echo -e "   ${GREEN}${REDIRECT_URI}${NC}"
echo "4. Click 'Save'"
echo ""
read -p "Press Enter after completing Google configuration..."

# ==================== MICROSOFT CONFIGURATION ====================
echo -e "\n${GREEN}=== Configuring Microsoft Azure AD (Entra ID) ===${NC}"

# Check if az is authenticated
if ! az account show &>/dev/null; then
  echo -e "${RED}Error: Azure CLI is not authenticated${NC}"
  echo "Run: az login"
  exit 1
fi

# Try to find the app
echo "Searching for Microsoft app..."
APP_OBJECT_ID=$(az ad app list \
  --filter "appId eq '${MICROSOFT_CLIENT_ID}'" \
  --query "[0].id" \
  --output tsv 2>/dev/null || echo "")

if [ -z "$APP_OBJECT_ID" ] || [ "$APP_OBJECT_ID" == "null" ]; then
  echo -e "${YELLOW}App not found in current tenant. Manual configuration required:${NC}"
  echo "1. Open: https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps"
  echo "2. Search for app with Client ID: ${MICROSOFT_CLIENT_ID}"
  echo "3. Click on the app → Authentication"
  echo "4. Under 'Redirect URIs', click 'Add a platform' → 'Web'"
  echo "5. Add:"
  echo -e "   ${GREEN}${REDIRECT_URI}${NC}"
  echo "6. Click 'Configure'"
  echo ""
  read -p "Press Enter after completing Microsoft configuration..."
else
  echo -e "App found! Object ID: ${GREEN}${APP_OBJECT_ID}${NC}"
  
  # Get current redirect URIs
  CURRENT_URIS=$(az ad app show --id "$APP_OBJECT_ID" --query "web.redirectUris" --output json)
  echo "Current redirect URIs: $CURRENT_URIS"
  
  # Check if our URI is already present
  if echo "$CURRENT_URIS" | jq -e ".[] | select(. == \"$REDIRECT_URI\")" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Redirect URI already configured!${NC}"
  else
    echo "Adding redirect URI..."
    
    # Merge new URI with existing ones
    NEW_URIS=$(echo "$CURRENT_URIS" | jq ". + [\"$REDIRECT_URI\"]")
    
    # Update the app
    az ad app update \
      --id "$APP_OBJECT_ID" \
      --web-redirect-uris $(echo "$NEW_URIS" | jq -r '.[]') \
      >/dev/null 2>&1
    
    echo -e "${GREEN}✓ Redirect URI added successfully!${NC}"
  fi
fi

# ==================== VALIDATION ====================
echo -e "\n${GREEN}=== Validation ===${NC}"
echo "Testing redirect URIs with Cognito..."

# Test Google
echo -n "Google OAuth: "
GOOGLE_TEST_URL="https://${COGNITO_DOMAIN}/oauth2/authorize?redirect_uri=http://localhost:5173/auth/callback&response_type=code&client_id=$(aws cognito-idp describe-user-pool-client --user-pool-id us-east-1_sztMWSEm4 --client-id 4e0reesiair18vo4ebfjp1d73q --query 'UserPoolClient.ClientId' --output text)&identity_provider=Google&scope=email+openid+profile"
if curl -s -o /dev/null -w "%{http_code}" -L "$GOOGLE_TEST_URL" | grep -q "302\|200"; then
  echo -e "${GREEN}✓ OK${NC}"
else
  echo -e "${RED}✗ Failed${NC}"
fi

# Test Microsoft
echo -n "Microsoft OAuth: "
MICROSOFT_TEST_URL="https://${COGNITO_DOMAIN}/oauth2/authorize?redirect_uri=http://localhost:5173/auth/callback&response_type=code&client_id=$(aws cognito-idp describe-user-pool-client --user-pool-id us-east-1_sztMWSEm4 --client-id 4e0reesiair18vo4ebfjp1d73q --query 'UserPoolClient.ClientId' --output text)&identity_provider=Microsoft&scope=email+openid+profile"
if curl -s -o /dev/null -w "%{http_code}" -L "$MICROSOFT_TEST_URL" | grep -q "302\|200"; then
  echo -e "${GREEN}✓ OK${NC}"
else
  echo -e "${RED}✗ Failed${NC}"
fi

echo -e "\n${GREEN}Configuration complete!${NC}"
echo "Test the OAuth flow at: http://localhost:5173/"
