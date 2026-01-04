#!/bin/bash

# AWS CloudFormation Stack Cleanup Script

# Configuration
STACK_NAME="${STACK_NAME:-my-cf-stack}"
REGION="${AWS_REGION:-us-east-1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}CloudFormation Stack Cleanup${NC}"
echo -e "Stack Name: ${STACK_NAME}"
echo -e "Region: ${REGION}"
echo ""

# Check if stack exists
echo -e "${YELLOW}Checking if stack exists...${NC}"
if ! aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${REGION} &> /dev/null; then
    echo -e "${RED}Stack ${STACK_NAME} does not exist in region ${REGION}${NC}"
    exit 1
fi

# Get stack status
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --query 'Stacks[0].StackStatus' \
    --output text)

echo -e "Current status: ${STACK_STATUS}"
echo ""

# Confirm deletion
read -p "Are you sure you want to delete this stack? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Delete the stack
echo -e "${YELLOW}Deleting stack...${NC}"
aws cloudformation delete-stack \
    --stack-name ${STACK_NAME} \
    --region ${REGION}

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to initiate stack deletion.${NC}"
    exit 1
fi

echo -e "${YELLOW}Waiting for stack deletion to complete...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"

aws cloudformation wait stack-delete-complete \
    --stack-name ${STACK_NAME} \
    --region ${REGION}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Stack deleted successfully!${NC}"
else
    echo -e "${RED}Stack deletion failed or timed out.${NC}"
    echo -e "${YELLOW}Check the AWS Console for more details.${NC}"
    exit 1
fi
