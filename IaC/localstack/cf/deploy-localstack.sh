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