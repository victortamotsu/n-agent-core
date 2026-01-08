#!/bin/bash
# n-agent - Terraform Provisioning Script
# Provisions Cognito, API Gateway, and Lambda BFF infrastructure

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✓ ${NC}$1"
}

log_warning() {
    echo -e "${YELLOW}⚠ ${NC}$1"
}

log_error() {
    echo -e "${RED}✗ ${NC}$1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Terraform
    if ! command -v terraform &>/dev/null; then
        log_error "Terraform not found. Install from: https://www.terraform.io/downloads"
        exit 1
    fi
    log_success "Terraform $(terraform version -json | jq -r '.terraform_version')"
    
    # AWS CLI
    if ! command -v aws &>/dev/null; then
        log_error "AWS CLI not found. Install from: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        log_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log_success "AWS Account: $ACCOUNT_ID"
    
    # Check AgentCore status
    log_info "Checking AgentCore Runtime status..."
    cd ../../../agent
    
    if ! command -v agentcore &>/dev/null; then
        log_warning "agentcore CLI not found. Make sure agent is deployed."
    else
        AGENT_STATUS=$(agentcore status 2>&1 || echo "ERROR")
        
        if echo "$AGENT_STATUS" | grep -q "READY\|Deployed"; then
            log_success "AgentCore Runtime is READY"
        else
            log_warning "AgentCore Runtime may not be deployed. Status:"
            echo "$AGENT_STATUS"
        fi
    fi
    
    cd - > /dev/null
}

# Validate terraform.tfvars
validate_tfvars() {
    log_info "Validating terraform.tfvars..."
    
    if [[ ! -f terraform.tfvars ]]; then
        log_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        log_warning "⚠️  Edit terraform.tfvars with your values before proceeding!"
        log_warning "    Required: agentcore_agent_id, agentcore_agent_arn"
        log_warning "    Optional: OAuth credentials (google_*, microsoft_*)"
        read -p "Press Enter when ready, or Ctrl+C to cancel..."
    else
        log_success "terraform.tfvars found"
    fi
    
    # Check for required values
    if grep -q 'agentcore_agent_id.*=.*""' terraform.tfvars || \
       ! grep -q 'agentcore_agent_id' terraform.tfvars; then
        log_error "agentcore_agent_id is empty or missing in terraform.tfvars"
        log_error "Get it from: cd ../../../agent && agentcore status"
        exit 1
    fi
    
    log_success "Required variables are set"
}

# Terraform init
terraform_init() {
    log_info "Initializing Terraform..."
    
    if ! terraform init; then
        log_error "Terraform init failed"
        log_warning "If backend S3 error, comment out 'backend \"s3\"' block in main.tf"
        log_warning "Or create backend: cd ../../bootstrap && terraform apply"
        exit 1
    fi
    
    log_success "Terraform initialized"
}

# Terraform plan
terraform_plan() {
    log_info "Planning infrastructure changes..."
    
    if ! terraform plan -out=tfplan; then
        log_error "Terraform plan failed"
        exit 1
    fi
    
    log_success "Plan created: tfplan"
    log_warning "Review the plan carefully before applying!"
    log_warning "Expected resources: ~15-20 (Cognito, API Gateway, Lambda, integrations)"
    
    read -p "Proceed with terraform apply? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        log_warning "Aborted by user"
        exit 0
    fi
}

# Terraform apply
terraform_apply() {
    log_info "Applying infrastructure changes..."
    
    if ! terraform apply tfplan; then
        log_error "Terraform apply failed"
        exit 1
    fi
    
    log_success "Infrastructure provisioned successfully!"
}

# Capture outputs
capture_outputs() {
    log_info "Capturing Terraform outputs..."
    
    terraform output -json > outputs.json
    
    API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null || echo "")
    COGNITO_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
    COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id 2>/dev/null || echo "")
    LAMBDA_BFF=$(terraform output -raw lambda_bff_function_name 2>/dev/null || echo "")
    
    log_success "Outputs saved to: outputs.json"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 DEPLOYMENT SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 API Gateway:"
    echo "   Endpoint: $API_ENDPOINT"
    echo ""
    echo "🔐 Cognito:"
    echo "   User Pool ID: $COGNITO_POOL_ID"
    echo "   Client ID: $COGNITO_CLIENT_ID"
    echo ""
    echo "⚡ Lambda BFF:"
    echo "   Function: $LAMBDA_BFF"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run tests
run_tests() {
    log_info "Running health check..."
    
    if [[ -n "$API_ENDPOINT" ]]; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/health" || echo "000")
        
        if [[ "$HTTP_CODE" == "200" ]]; then
            log_success "Health check passed (HTTP $HTTP_CODE)"
        else
            log_warning "Health check returned HTTP $HTTP_CODE"
            log_warning "Check Lambda logs: aws logs tail /aws/lambda/$LAMBDA_BFF --follow"
        fi
    else
        log_warning "API endpoint not available, skipping health check"
    fi
}

# GitHub Secrets
suggest_github_secrets() {
    echo ""
    log_info "GitHub Secrets for CI/CD:"
    echo ""
    echo "Run these commands to add secrets to GitHub:"
    echo ""
    echo "  gh secret set API_ENDPOINT --body \"$API_ENDPOINT\""
    echo "  gh secret set COGNITO_USER_POOL_ID --body \"$COGNITO_POOL_ID\""
    echo "  gh secret set COGNITO_CLIENT_ID --body \"$COGNITO_CLIENT_ID\""
    echo "  gh secret set LAMBDA_BFF_FUNCTION_NAME --body \"$LAMBDA_BFF\""
    echo ""
}

# Next steps
show_next_steps() {
    echo ""
    log_info "Next steps:"
    echo ""
    echo "  1. Create test user in Cognito:"
    echo "     aws cognito-idp admin-create-user \\"
    echo "       --user-pool-id \"$COGNITO_POOL_ID\" \\"
    echo "       --username \"test@example.com\" \\"
    echo "       --temporary-password \"TempPass123!\" \\"
    echo "       --user-attributes Name=email,Value=test@example.com"
    echo ""
    echo "  2. Run integration tests:"
    echo "     cd ../../../../scripts"
    echo "     export API_ENDPOINT=\"$API_ENDPOINT\""
    echo "     export COGNITO_USER_POOL_ID=\"$COGNITO_POOL_ID\""
    echo "     export COGNITO_CLIENT_ID=\"$COGNITO_CLIENT_ID\""
    echo "     ./test-api-integration.sh"
    echo ""
    echo "  3. Monitor logs:"
    echo "     aws logs tail /aws/lambda/$LAMBDA_BFF --follow"
    echo ""
    echo "  4. Deploy frontend with API endpoint:"
    echo "     cd ../../../../apps/web-client"
    echo "     echo \"VITE_API_URL=$API_ENDPOINT\" > .env.production"
    echo ""
}

# Main
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 n-agent Infrastructure Provisioning"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Change to terraform prod directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR/../infra/terraform/environments/prod" || exit 1
    
    check_prerequisites
    validate_tfvars
    terraform_init
    terraform_plan
    terraform_apply
    capture_outputs
    run_tests
    suggest_github_secrets
    show_next_steps
    
    log_success "Provisioning complete! 🎉"
}

main "$@"
