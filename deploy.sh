#!/bin/bash

# AWS CloudFormation Stack Deployment Script
# This script uploads templates to S3 and creates the CloudFormation stack

# Configuration
STACK_NAME="${STACK_NAME:-my-cf-stack}"
S3_BUCKET="${S3_BUCKET:-}"  # Set via environment variable or prompt
REGION="${AWS_REGION:-us-east-1}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}AWS CloudFormation Deployment Script${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Prompt for S3 bucket if not set
if [ -z "$S3_BUCKET" ]; then
    echo -e "${YELLOW}Please enter your S3 bucket name:${NC}"
    read -p "S3 Bucket: " S3_BUCKET
    
    if [ -z "$S3_BUCKET" ]; then
        echo -e "${RED}Error: S3 bucket name is required.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Configuration:${NC}"
echo -e "  Stack Name: ${STACK_NAME}"
echo -e "  S3 Bucket: ${S3_BUCKET}"
echo -e "  Region: ${REGION}"
echo ""

echo -e "${YELLOW}Starting CloudFormation deployment...${NC}"

# Check if S3 bucket exists, if not create it
echo -e "${YELLOW}Checking if S3 bucket exists...${NC}"
if aws s3 ls "s3://${S3_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo -e "${YELLOW}Creating S3 bucket ${S3_BUCKET}...${NC}"
    if [ "$REGION" = "us-east-1" ]; then
        aws s3 mb "s3://${S3_BUCKET}"
    else
        aws s3 mb "s3://${S3_BUCKET}" --region ${REGION}
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create S3 bucket. It may already exist or you may not have permissions.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}S3 bucket ${S3_BUCKET} exists.${NC}"
fi

# Upload templates to S3
echo -e "${YELLOW}Uploading templates to S3...${NC}"
aws s3 sync ./templates/ "s3://${S3_BUCKET}/templates/" --delete

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to upload templates to S3.${NC}"
    exit 1
fi

echo -e "${GREEN}Templates uploaded successfully!${NC}"

# Validate the template
echo -e "${YELLOW}Validating CloudFormation template...${NC}"
aws cloudformation validate-template \
    --template-body file://parent-stack.yaml \
    --region ${REGION} > /dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}Template validation failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Template validated successfully!${NC}"

# Create or update the CloudFormation stack
echo -e "${YELLOW}Deploying CloudFormation stack...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"

aws cloudformation deploy \
    --template-file parent-stack.yaml \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides S3BucketName=${S3_BUCKET} \
    --no-fail-on-empty-changeset

DEPLOY_EXIT_CODE=$?

if [ $DEPLOY_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Stack deployed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Stack outputs:${NC}"
    aws cloudformation describe-stacks \
        --stack-name ${STACK_NAME} \
        --region ${REGION} \
        --query 'Stacks[0].Outputs' \
        --output table
    
    echo ""
    echo -e "${GREEN}Stack resources:${NC}"
    aws cloudformation list-stack-resources \
        --stack-name ${STACK_NAME} \
        --region ${REGION} \
        --query 'StackResourceSummaries[*].[LogicalResourceId,ResourceType,ResourceStatus]' \
        --output table
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Stack deployment failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Recent stack events:${NC}"
    aws cloudformation describe-stack-events \
        --stack-name ${STACK_NAME} \
        --region ${REGION} \
        --max-items 10 \
        --query 'StackEvents[*].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
        --output table
    exit 1
fi

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${BLUE}To delete this stack, run:${NC}"
echo -e "  aws cloudformation delete-stack --stack-name ${STACK_NAME} --region ${REGION}"
