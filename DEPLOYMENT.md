# AWS CloudFormation Stack Deployment Guide

## Prerequisites
1. AWS CLI installed and configured with credentials
2. An S3 bucket to store templates (or the script will create one)
3. Appropriate IAM permissions to create CloudFormation stacks and S3 buckets

## Quick Start

### Option 1: Using the deployment script (Recommended)

1. **Edit the configuration** in `deploy.sh`:
   ```bash
   STACK_NAME="my-cf-stack"        # Your stack name
   S3_BUCKET="your-bucket-name"    # Your S3 bucket name
   REGION="us-east-1"               # Your AWS region
   ```

2. **Make the script executable**:
   ```bash
   chmod +x deploy.sh
   ```

3. **Run the deployment**:
   ```bash
   ./deploy.sh
   ```

### Option 2: Manual deployment

1. **Create an S3 bucket** (if you don't have one):
   ```bash
   aws s3 mb s3://your-bucket-name --region us-east-1
   ```

2. **Upload templates to S3**:
   ```bash
   aws s3 sync ./templates/ s3://your-bucket-name/templates/
   ```

3. **Update parent-stack.yaml**: Replace `YOUR_BUCKET` with your actual S3 bucket name

4. **Deploy the stack**:
   ```bash
   aws cloudformation create-stack \
     --stack-name my-cf-stack \
     --template-body file://parent-stack.yaml \
     --region us-east-1 \
     --capabilities CAPABILITY_IAM
   ```

5. **Monitor the stack creation**:
   ```bash
   aws cloudformation describe-stacks --stack-name my-cf-stack --region us-east-1
   ```

   Or watch events in real-time:
   ```bash
   aws cloudformation describe-stack-events --stack-name my-cf-stack --region us-east-1
   ```

## Updating the Stack

To update an existing stack:
```bash
aws cloudformation update-stack \
  --stack-name my-cf-stack \
  --template-body file://parent-stack.yaml \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM
```

Or use the deploy script which handles both create and update:
```bash
./deploy.sh
```

## Deleting the Stack

To delete the stack and all its resources:
```bash
aws cloudformation delete-stack --stack-name my-cf-stack --region us-east-1
```

Monitor deletion:
```bash
aws cloudformation wait stack-delete-complete --stack-name my-cf-stack --region us-east-1
```

## Troubleshooting

### View stack events
```bash
aws cloudformation describe-stack-events \
  --stack-name my-cf-stack \
  --region us-east-1 \
  --max-items 20
```

### Check stack status
```bash
aws cloudformation describe-stacks \
  --stack-name my-cf-stack \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

### View outputs
```bash
aws cloudformation describe-stacks \
  --stack-name my-cf-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs'
```

## Configuration

Before deploying, ensure you have:
- Valid AWS credentials configured (`aws configure`)
- Necessary IAM permissions
- An S3 bucket for storing templates (or permissions to create one)
- The correct region specified

## Notes

- The parent stack references nested stacks stored in S3
- Make sure all template files are valid before uploading
- Use `--capabilities CAPABILITY_IAM` if your templates create IAM resources
- The deployment script automatically handles template uploads and bucket creation
