#!/bin/bash
# ============================================================
# Bootstrap Script: Creates S3 bucket and DynamoDB table
# for Terraform remote state management
# ============================================================

set -e  # Exit on any error

# ---- CONFIGURE THESE VALUES ----
AWS_REGION="us-east-1"
PROJECT_NAME="eks-demo"
ENVIRONMENT="dev"
# ---------------------------------

BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ENVIRONMENT}-$(aws sts get-caller-identity --query Account --output text)"
DYNAMODB_TABLE="${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}"

echo "🪣 Checking S3 bucket..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Bucket already exists in your account"
else
  echo "Creating bucket..."
  
  if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi
fi


echo "🔒 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "🔐 Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "🚫 Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "📋 Creating DynamoDB table: $DYNAMODB_TABLE"
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" 2>/dev/null || echo "DynamoDB table already exists"

echo ""
echo "✅ Bootstrap complete!"
echo "   S3 Bucket:      $BUCKET_NAME"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
echo "   Region:         $AWS_REGION"
echo ""
echo "📝 Update your backend.tf files with:"
echo "   bucket = \"$BUCKET_NAME\""
echo "   dynamodb_table = \"$DYNAMODB_TABLE\""
