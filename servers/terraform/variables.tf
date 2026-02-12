# =============================================================================
# DevStack - Terraform Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "devstack"
}

variable "availability_zone" {
  description = "Availability zone for subnet"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 100
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr" {
  description = "CIDR blocks allowed for HTTP/HTTPS and OpenStack APIs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Name of existing EC2 key pair (required if public_key_path is empty)"
  type        = string
  default     = "devops9x"
}

variable "public_key_path" {
  description = "Path to SSH public key file (creates new key pair if set)"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script for EC2 instance (overrides default swap script if set)"
  type        = string
  default     = ""
}
