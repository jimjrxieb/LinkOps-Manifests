#!/bin/bash
# Deploy CloudFormation stacks for Portfolio infrastructure
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}
REGION=${AWS_REGION:-us-east-1}

echo "Deploying Portfolio CloudFormation stacks"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

deploy_stack() {
    local template=$1
    local stack_name=$2
    local params=$3

    echo -e "${YELLOW}Deploying $stack_name...${NC}"

    aws cloudformation deploy \
        --template-file "$template" \
        --stack-name "$stack_name" \
        --parameter-overrides $params \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION" \
        --no-fail-on-empty-changeset

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $stack_name deployed successfully${NC}"
    else
        echo -e "${RED}✗ $stack_name deployment failed${NC}"
        exit 1
    fi
    echo ""
}

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity > /dev/null 2>&1 || {
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
}
echo -e "${GREEN}✓ AWS credentials valid${NC}"
echo ""

# Deploy stacks in order
cd "$(dirname "$0")"

# 1. ECR Repositories
deploy_stack \
    "ecr-repositories.yaml" \
    "portfolio-ecr-$ENVIRONMENT" \
    "Environment=$ENVIRONMENT"

# 2. Secrets
deploy_stack \
    "secrets.yaml" \
    "portfolio-secrets-$ENVIRONMENT" \
    "Environment=$ENVIRONMENT"

# 3. S3 Artifacts
deploy_stack \
    "s3-artifacts.yaml" \
    "portfolio-s3-$ENVIRONMENT" \
    "Environment=$ENVIRONMENT"

# 4. IAM Roles
deploy_stack \
    "iam-roles.yaml" \
    "portfolio-iam-$ENVIRONMENT" \
    "Environment=$ENVIRONMENT K8sNamespace=portfolio K8sServiceAccountName=portfolio-app"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All stacks deployed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Set secret values:"
echo "   aws secretsmanager put-secret-value --secret-id portfolio/$ENVIRONMENT/claude-api-key --secret-string 'your-key'"
echo ""
echo "2. Get ECR repository URIs:"
echo "   aws cloudformation describe-stacks --stack-name portfolio-ecr-$ENVIRONMENT --query 'Stacks[0].Outputs'"
echo ""
echo "3. Update Helm values.yaml with ECR URIs"
