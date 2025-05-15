# Running Saminda Laravel Application on LocalStack

This README provides step-by-step instructions on how to run the Saminda Laravel application CloudFormation template using LocalStack for local development and testing.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** - LocalStack runs as a Docker container
- **Docker Compose** (optional but recommended)
- **AWS CLI** - to interact with LocalStack
- **LocalStack** - for emulating AWS services locally

## Step-by-Step Guide

### 1. Install and Start LocalStack

Using Docker directly:

```bash
# Pull the LocalStack image
docker pull localstack/localstack

# Start LocalStack
docker run -d --name localstack -p 4566:4566 -p 4510-4559:4510-4559 localstack/localstack
```

Alternatively, using Docker Compose:

```bash
# Create a docker-compose.yml file
echo 'version: "3.8"
services:
  localstack:
    container_name: localstack
    image: localstack/localstack
    ports:
      - "4566:4566"
      - "4510-4559:4510-4559"
    environment:
      - SERVICES=cloudformation,ec2,route53,iam
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"' > docker-compose.yml

# Start LocalStack
docker-compose up -d
```

### 2. Configure AWS CLI for LocalStack

Set up your AWS CLI to point to your LocalStack instance:

```bash
aws configure --profile localstack
```

Enter the following values:
- AWS Access Key ID: `test`
- AWS Secret Access Key: `test`
- Default region name: `us-east-1`
- Default output format: `json`

### 3. Create a Deployment Script

Create a file called `deploy-localstack.sh` with the following content:

```bash
#!/bin/bash

# Configure AWS CLI to use LocalStack
export AWS_PROFILE=localstack
export AWS_ENDPOINT_URL=http://localhost:4566

# Create EC2 key pair (required by the template)
aws ec2 create-key-pair --key-name saminda-key --endpoint-url $AWS_ENDPOINT_URL --query "KeyMaterial" --output text > saminda-key.pem
chmod 400 saminda-key.pem

# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name saminda-stack \
  --template-body file://saminda-infrastructure.yml \
  --parameters ParameterKey=KeyName,ParameterValue=saminda-key \
               ParameterKey=InstanceType,ParameterValue=t2.micro \
               ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0 \
  --endpoint-url $AWS_ENDPOINT_URL
  
# Check stack creation status
echo "Waiting for stack creation..."
aws cloudformation wait stack-create-complete \
  --stack-name saminda-stack \
  --endpoint-url $AWS_ENDPOINT_URL

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name saminda-stack \
  --endpoint-url $AWS_ENDPOINT_URL \
  --query "Stacks[0].Outputs"
```

Make the script executable:

```bash
chmod +x deploy-localstack.sh
```

### 4. Run the Deployment Script

```bash
./deploy-localstack.sh
```

### 5. Verify the Deployed Resources

After deployment, verify the created resources:

```bash
# List VPCs
aws ec2 describe-vpcs --endpoint-url http://localhost:4566

# List EC2 instances
aws ec2 describe-instances --endpoint-url http://localhost:4566

# List security groups
aws ec2 describe-security-groups --endpoint-url http://localhost:4566
```

## Limitations and Considerations

1. **EC2 Simulation**: LocalStack doesn't create actual EC2 instances; it simulates the API calls. The `UserData` script won't actually run.

2. **AMI Limitations**: The AMI ID in the template (`ami-0c7217cdde317cfec`) will be accepted but not validated by LocalStack.

3. **Network Limitations**: Your application won't be accessible via the outputs shown in the CloudFormation stack outputs since there's no actual web server running.

4. **LocalStack Pro Features**: Some EC2 features might require LocalStack Pro. The free tier has limited support for EC2.

5. **Testing Scope**: This setup is primarily for testing infrastructure provisioning logic, not application functionality.

## Cleaning Up

To remove the stack and all created resources:

```bash
aws cloudformation delete-stack \
  --stack-name saminda-stack \
  --endpoint-url http://localhost:4566
```

To stop LocalStack:

```bash
# If using Docker directly
docker stop localstack
docker rm localstack

# If using Docker Compose
docker-compose down
```

## Troubleshooting

- **Endpoint Connection Errors**: Ensure LocalStack is running and accessible at `http://localhost:4566`
- **Resource Creation Failures**: Check LocalStack logs for detailed error messages:
  ```bash
  docker logs localstack
  ```
- **Missing Services**: Some AWS services might not be fully implemented in LocalStack free tier