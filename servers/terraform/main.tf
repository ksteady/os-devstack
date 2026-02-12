# =============================================================================
# DevStack - AWS Infrastructure (Terraform)
# Resources prefix: devstack
# EC2: t3.xlarge (4 vCPU, 16 GB RAM)
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az = var.availability_zone != null ? var.availability_zone : data.aws_availability_zones.available.names[0]

  user_data_swap = <<-EOT
#!/bin/bash
set -e
SWAP_FILE="/swapfile"
SWAP_SIZE_GB=8
echo "Creating 8GB swap file at $$SWAP_FILE..."
sudo fallocate -l 8G $$SWAP_FILE
sudo chmod 600 $$SWAP_FILE
sudo mkswap $$SWAP_FILE
sudo swapon $$SWAP_FILE
if ! grep -q "^$$SWAP_FILE" /etc/fstab; then
  echo "$$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi
sudo sysctl -w vm.swappiness=100
echo "vm.swappiness=100" | sudo tee -a /etc/sysctl.d/99-devstack.conf 2>/dev/null || true
echo "Swap configured successfully."
free -h
EOT
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*", "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "devstack" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "devstack" {
  vpc_id = aws_vpc.devstack.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# -----------------------------------------------------------------------------
# Public Subnet
# -----------------------------------------------------------------------------
resource "aws_subnet" "devstack" {
  vpc_id                  = aws_vpc.devstack.id
  cidr_block              = var.subnet_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-subnet"
  }
}

# -----------------------------------------------------------------------------
# Route Table
# -----------------------------------------------------------------------------
resource "aws_route_table" "devstack" {
  vpc_id = aws_vpc.devstack.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devstack.id
  }

  tags = {
    Name = "${var.name_prefix}-rt"
  }
}

resource "aws_route_table_association" "devstack" {
  subnet_id      = aws_subnet.devstack.id
  route_table_id = aws_route_table.devstack.id
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "devstack" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for DevStack EC2 instance"
  vpc_id      = aws_vpc.devstack.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP - Horizon
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # HTTPS - Horizon
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Keystone
  ingress {
    description = "Keystone API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Glance
  ingress {
    description = "Glance API"
    from_port   = 9292
    to_port     = 9292
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Nova
  ingress {
    description = "Nova API"
    from_port   = 8774
    to_port     = 8774
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Neutron
  ingress {
    description = "Neutron API"
    from_port   = 9696
    to_port     = 9696
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Cinder
  ingress {
    description = "Cinder API"
    from_port   = 8776
    to_port     = 8776
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # VNC Console (novnc)
  ingress {
    description = "novnc"
    from_port   = 6080
    to_port     = 6080
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Outbound
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}

# -----------------------------------------------------------------------------
# Key Pair (optional - use existing key if key_name is set)
# -----------------------------------------------------------------------------
resource "aws_key_pair" "devstack" {
  count = var.public_key_path != "" ? 1 : 0

  key_name   = "${var.name_prefix}-key"
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.name_prefix}-key"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance - t3.xlarge
# -----------------------------------------------------------------------------
resource "aws_instance" "devstack" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.public_key_path != "" ? aws_key_pair.devstack[0].key_name : var.key_name
  subnet_id              = aws_subnet.devstack.id
  vpc_security_group_ids = [aws_security_group.devstack.id]

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = var.user_data != "" ? var.user_data : local.user_data_swap

  tags = {
    Name = "${var.name_prefix}-instance"
  }
}
