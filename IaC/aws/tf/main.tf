provider "aws" {
  region = "us-east-1"
}

# Variables (equivalent to CloudFormation Parameters)
variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Must be a valid EC2 instance type (t2.micro, t2.small, or t2.medium)."
  }
}

variable "ssh_location" {
  description = "The IP address range that can SSH to the EC2 instance"
  type        = string
  default     = "0.0.0.0/0"
  
  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.ssh_location))
    error_message = "Must be a valid IP CIDR range of the form x.x.x.x/x."
  }
}

# VPC
resource "aws_vpc" "saminda_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "saminda-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "saminda_public_subnet" {
  vpc_id                  = aws_vpc.saminda_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "saminda-public-subnet"
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway
resource "aws_internet_gateway" "saminda_igw" {
  vpc_id = aws_vpc.saminda_vpc.id
  
  tags = {
    Name = "saminda-igw"
  }
}

# Public Route Table
resource "aws_route_table" "saminda_public_rt" {
  vpc_id = aws_vpc.saminda_vpc.id
  
  tags = {
    Name = "saminda-public-rt"
  }
}

# Public Route
resource "aws_route" "saminda_public_route" {
  route_table_id         = aws_route_table.saminda_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.saminda_igw.id
  
  depends_on = [aws_internet_gateway.saminda_igw]
}

# Public Subnet Route Table Association
resource "aws_route_table_association" "saminda_public_rt_association" {
  subnet_id      = aws_subnet.saminda_public_subnet.id
  route_table_id = aws_route_table.saminda_public_rt.id
}

# Security Group
resource "aws_security_group" "saminda_sg" {
  name        = "saminda-sg"
  description = "Enable SSH and Web access"
  vpc_id      = aws_vpc.saminda_vpc.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_location]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "saminda-sg"
  }
}

# EC2 Instance
resource "aws_instance" "saminda_instance" {
  ami           = "ami-0c7217cdde317cfec"  # Amazon Linux 2023 AMI (us-east-1)
  instance_type = var.instance_type
  key_name      = var.key_name
  
  network_interface {
    network_interface_id = aws_network_interface.saminda_nic.id
    device_index         = 0
  }
  
  user_data = <<-EOF
    #!/bin/bash -ex
    
    # Update system
    dnf update -y
    
    # Install Docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Add ec2-user to the docker group
    usermod -a -G docker ec2-user
    
    # Install Git
    dnf install -y git
    
    # Create app directory
    mkdir -p /var/www/saminda
    chown ec2-user:ec2-user /var/www/saminda
  EOF
  
  tags = {
    Name = "saminda-instance"
  }
}

# Network Interface
resource "aws_network_interface" "saminda_nic" {
  subnet_id       = aws_subnet.saminda_public_subnet.id
  security_groups = [aws_security_group.saminda_sg.id]
}

# Elastic IP
resource "aws_eip" "saminda_eip" {
  domain = "vpc"
  
  instance                  = aws_instance.saminda_instance.id
  depends_on                = [aws_internet_gateway.saminda_igw]
  
  tags = {
    Name = "saminda-eip"
  }
}

# Outputs
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.saminda_instance.public_ip
}

output "instance_elastic_ip" {
  description = "The Elastic IP address of the EC2 instance"
  value       = aws_eip.saminda_eip.public_ip
}

output "website_url" {
  description = "URL to access the Laravel application"
  value       = "http://${aws_eip.saminda_eip.public_ip}/"
}