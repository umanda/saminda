# LocalStack configuration for testing
# Save this as localstack.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  # LocalStack configuration
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  
  # LocalStack endpoint configuration
  endpoints {
    ec2            = "http://localhost:4566"
    route53        = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
  }
  
  # Mock credentials for LocalStack
  access_key = "test"
  secret_key = "test"
}

# For testing, use a dummy AMI ID that works with LocalStack
resource "aws_ami" "dummy_ami" {
  name                = "amazon-linux-2023"
  virtualization_type = "hvm"
  root_device_name    = "/dev/xvda"
  
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 8
  }
}