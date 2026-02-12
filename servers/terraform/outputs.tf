# =============================================================================
# DevStack - Terraform Outputs
# =============================================================================

output "vpc_id" {
  description = "ID of the DevStack VPC"
  value       = aws_vpc.devstack.id
}

output "subnet_id" {
  description = "ID of the DevStack subnet"
  value       = aws_subnet.devstack.id
}

output "security_group_id" {
  description = "ID of the DevStack security group"
  value       = aws_security_group.devstack.id
}

output "instance_id" {
  description = "ID of the DevStack EC2 instance"
  value       = aws_instance.devstack.id
}

output "instance_public_ip" {
  description = "Public IP of the DevStack EC2 instance"
  value       = aws_instance.devstack.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the DevStack EC2 instance"
  value       = aws_instance.devstack.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.devstack.public_ip}"
}

output "horizon_url" {
  description = "Horizon dashboard URL (after DevStack is installed)"
  value       = "http://${aws_instance.devstack.public_ip}/"
}
