# LocalStack Testing for Terraform Saminda Application
# Save this as README.md

## Testing Terraform Configuration with LocalStack

This guide explains how to test your Terraform configuration for AWS resources locally using LocalStack.

### Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Terraform](https://www.terraform.io/downloads.html) (v0.12+)
- [AWS CLI](https://aws.amazon.com/cli/) (optional, for verification)

### Files Overview

- `main.tf` - Original Terraform configuration for AWS
- `main.tf.localstack` - Modified Terraform configuration for LocalStack testing
- `localstack.tf` - LocalStack provider configuration
- `test-localstack.sh` - Testing script

### Testing Steps

1. **Start LocalStack**

   ```bash
   docker run -d --name localstack \
     -p 4566:4566 \
     -p 4571:4571 \
     -e SERVICES=ec2,route53,cloudformation \
     -e DEBUG=1 \
     localstack/localstack
   ```

2. **Prepare Testing Files**

   ```bash
   # Copy testing files
   cp main.tf.localstack main.tf
   ```

3. **Initialize Terraform**

   ```bash
   terraform init
   ```

4. **Apply Configuration**

   ```bash
   terraform apply
   ```

5. **Verify Resources (using AWS CLI)**

   ```bash
   # Configure AWS CLI for LocalStack
   export AWS_ACCESS_KEY_ID=test
   export AWS_SECRET_ACCESS_KEY=test
   export AWS_DEFAULT_REGION=us-east-1
   
   # Check created resources
   aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs
   aws --endpoint-url=http://localhost:4566 ec2 describe-instances
   aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups
   ```

6. **Automated Testing**

   You can use the provided script for automated testing:

   ```bash
   chmod +x test-localstack.sh
   ./test-localstack.sh
   ```

7. **Cleanup**

   ```bash
   # Destroy Terraform resources
   terraform destroy
   
   # Stop LocalStack
   docker stop localstack
   docker rm localstack
   ```

### Troubleshooting

- If you see endpoint errors, ensure LocalStack is running and accessible.
- LocalStack may not support all AWS features. Check the [LocalStack documentation](https://docs.localstack.cloud/) for limitations.

### LocalStack Limitations

When testing with LocalStack, be aware of these limitations:

1. Not all AWS services or features are fully supported
2. Real AWS credentials are not validated
3. Certain AWS-specific behaviors may differ
4. Network functionality is simulated

For production deployment, always test with real AWS resources before deploying.