# 🚀 Quick Start - Terraform Deploy

<!-- Test change to trigger deploy -->

## 1️⃣ Bootstrap Backend (only once)

```bash
cd infra/terraform/bootstrap
terraform init
terraform apply
```

**Output**:
- S3 bucket: `n-agent-terraform-state`
- DynamoDB table: `n-agent-terraform-locks`

---

## 2️⃣ Deploy Dev Environment

```bash
cd infra/terraform/environments/dev

# Initialize
terraform init

# Plan (review changes)
terraform plan \
  -var="whatsapp_verify_token=YOUR_TOKEN" \
  -var="whatsapp_access_token=YOUR_TOKEN" \
  -var="whatsapp_phone_number_id=YOUR_ID"

# Apply (deploy)
terraform apply \
  -var="whatsapp_verify_token=YOUR_TOKEN" \
  -var="whatsapp_access_token=YOUR_TOKEN" \
  -var="whatsapp_phone_number_id=YOUR_ID"
```

---

## 3️⃣ Get Outputs

```bash
terraform output

# Or JSON format
terraform output -json
```

**Key outputs**:
- `whatsapp_lambda_url`: Use this for Meta webhook
- `agentcore_memory_id`: For BEDROCK_AGENTCORE_MEMORY_ID
- `secrets_manager_arn`: For IAM policies

---

## 4️⃣ Deploy Prod (via CI/CD)

Just push to `main` branch:

```bash
git add .
git commit -m "feat: Deploy via Terraform"
git push origin main
```

GitHub Actions will:
1. ✅ Run lint + tests
2. ✅ Terraform plan
3. ✅ Terraform apply (auto-approved on main)

---

## ⚡ Quick Commands

```bash
# Check current state
terraform show

# List all resources
terraform state list

# Refresh outputs
terraform refresh

# Destroy everything (careful!)
terraform destroy
```

---

## 🔐 Secrets (already configured in GitHub)

All secrets are read automatically from GitHub Actions:

- `AWS_ACCESS_KEY_ID_PROD`
- `AWS_SECRET_ACCESS_KEY_PROD`
- `WHATSAPP_VERIFY_TOKEN`
- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- OAuth credentials (Google, Facebook, Microsoft)

No manual configuration needed! 🎉
