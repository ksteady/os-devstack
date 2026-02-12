# DevStack - AWS Infrastructure (Terraform)

Terraform cung cấp tài nguyên AWS cho DevStack:
- **EC2**: t3.xlarge (4 vCPU, 16 GB RAM)
- **VPC**, Subnet, Internet Gateway, Route Table
- **Security Group** với các port cần thiết cho OpenStack

## Prefix

Tất cả resource có prefix `devstack`:
- `devstack-vpc`
- `devstack-subnet`
- `devstack-sg`
- `devstack-instance`

## Yêu cầu

- Terraform >= 1.0
- AWS Provider ~> 5.0
- AWS credentials (environment variables hoặc `~/.aws/credentials`)

## Cách sử dụng

### 1. Cấu hình credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-southeast-1"
```

### 2. SSH Key

**Option A - Dùng key có sẵn:**
```bash
# Tạo file terraform.tfvars
key_name = "my-existing-key"
```

**Option B - Tạo key mới từ file public key:**
```bash
public_key_path = "~/.ssh/id_rsa.pub"
```

### 3. Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Output

Sau khi apply xong:
```bash
terraform output
# instance_public_ip
# ssh_command
# horizon_url
```

## Kết nối SSH

```bash
ssh -i your-key.pem ubuntu@<instance_public_ip>
```

## User Data - Swap

Instance tự động chạy script tạo **8GB swap** khi khởi động (cần thiết cho DevStack + Tempest). Để dùng user-data riêng, set biến `user_data` (sẽ override script swap mặc định).

## Cài đặt DevStack

Sau khi SSH vào instance:

```bash
git clone https://opendev.org/openstack/devstack
cd devstack
cp samples/local.conf local.conf
# Chỉnh sửa local.conf theo nhu cầu
./stack.sh
```

## Cấu trúc files

```
terraform/
├── main.tf              # VPC, Subnet, SG, EC2 + user_data swap script inline
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```
