# Script to set up and run Terraform with LocalStack
# Save as test-localstack.sh

set -e

echo "=== Setting up LocalStack testing environment ==="

# Check if LocalStack is running
if ! docker ps | grep -q localstack; then
  echo "Starting LocalStack..."
  docker run -d --name localstack \
    -p 4566:4566 \
    -p 4571:4571 \
    -e SERVICES=ec2,route53,cloudformation \
    -e DEBUG=1 \
    localstack/localstack
  
  # Wait for LocalStack to be ready
  echo "Waiting for LocalStack to be ready..."
  sleep 10
else
  echo "LocalStack is already running."
fi

# Prepare Terraform files for LocalStack testing
echo "Preparing Terraform files..."
cp main.tf.localstack main.tf.testing
cp localstack.tf .

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply the configuration
echo "Applying Terraform configuration to LocalStack..."
terraform apply -auto-approve

# Verify resources
echo "Verifying created resources..."
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 \
  aws --endpoint-url=http://localhost:4566 ec2 describe-instances

echo "=== Test completed successfully ==="