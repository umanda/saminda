#!/bin/bash

# === Ask User for Inputs ===
read -p "Enter Stack Name [default: saminda-stack]: " STACK_NAME
STACK_NAME=${STACK_NAME:-saminda-stack}

read -p "Enter Template File Path [default: saminda-infrastructure.yml]: " TEMPLATE_FILE
TEMPLATE_FILE=${TEMPLATE_FILE:-saminda-infrastructure.yml}

read -p "Enter EC2 Key Pair Name: " KEY_NAME
if [ -z "$KEY_NAME" ]; then
  echo "❌ Key Pair Name is required. Exiting."
  exit 1
fi

# === Execute CloudFormation Stack Creation ===
echo "🚀 Creating CloudFormation stack: $STACK_NAME"
aws cloudformation create-stack \
  --stack-name "$STACK_NAME" \
  --template-body "file://$TEMPLATE_FILE" \
  --parameters ParameterKey=KeyName,ParameterValue="$KEY_NAME"

# === Post-Command Status ===
if [ $? -eq 0 ]; then
  echo "✅ Stack creation initiated successfully."
  echo "🔍 Run 'aws cloudformation describe-stacks --stack-name $STACK_NAME' to monitor progress."
else
  echo "❌ Failed to initiate stack creation."
  exit 1
fi
