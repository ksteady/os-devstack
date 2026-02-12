#!/bin/bash
# Cài đặt Git và Terraform trên Ubuntu
# Usage: sudo ./install-git-terraform.sh

set -e

apt-get update
apt-get install -y git curl unzip

# Terraform
VERSION="1.9.0"
cd /tmp
curl -fsSL -o terraform.zip "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"
unzip -o terraform.zip
mv terraform /usr/local/bin/
rm terraform.zip

echo "Done. Git: $(git --version) | Terraform: $(terraform version | head -1)"
