# Script to setup Terraform S3 backend
# This needs to be run once before using Terraform

$BucketName = "n-agent-terraform-state"
$TableName = "n-agent-terraform-locks"
$Region = "us-east-1"

Write-Host "Creating S3 bucket for Terraform state..." -ForegroundColor Cyan
aws s3api create-bucket `
  --bucket $BucketName `
  --region $Region

Write-Host "Enabling versioning on S3 bucket..." -ForegroundColor Cyan
aws s3api put-bucket-versioning `
  --bucket $BucketName `
  --versioning-configuration Status=Enabled

Write-Host "Enabling encryption on S3 bucket..." -ForegroundColor Cyan
aws s3api put-bucket-encryption `
  --bucket $BucketName `
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

Write-Host "Blocking public access on S3 bucket..." -ForegroundColor Cyan
aws s3api put-public-access-block `
  --bucket $BucketName `
  --public-access-block-configuration `
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

Write-Host "Creating DynamoDB table for state locking..." -ForegroundColor Cyan
aws dynamodb create-table `
  --table-name $TableName `
  --attribute-definitions AttributeName=LockID,AttributeType=S `
  --key-schema AttributeName=LockID,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --region $Region

Write-Host "Terraform backend setup complete!" -ForegroundColor Green
Write-Host "Bucket: $BucketName"
Write-Host "DynamoDB Table: $TableName"
