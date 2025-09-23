# Task 02 — EC2 on AWS Free Tier (Terraform + Amazon Linux 2023 + user-data)

This lab launches a small **EC2** VM using **Terraform**, installs **nginx** via **user-data**, and serves a simple “Hello NEBo” page. It follows current HashiCorp AWS provider practices (no credentials in code; use your AWS CLI profile).

---

## What you deploy

- **EC2 instance**: Amazon Linux 2023 (AL2023), `t3.micro` (Free Tier eligible in many regions)
- **Security Group**:
  - Inbound **22/tcp** (SSH) from **your IP only**
  - Inbound **80/tcp** (HTTP) from anywhere (IPv4 + IPv6)
  - All outbound allowed
- **Key Pair**: Imported from your local public key
- **User data**: `bootstrap-nginx.sh` updates packages, installs nginx, and writes a minimal homepage

---

## Prerequisites

- AWS account (Free Tier), **IAM user** with programmatic access and **MFA**
- **AWS CLI** configured (`aws configure`) with your IAM user (not root)
- **Terraform** ≥ 1.6 installed
- Local SSH key available at `~/.ssh/nebo_aws.pub` (private key at `~/.ssh/nebo_aws`)

> Keep access keys **out of Terraform**; rely on the AWS CLI profile.

---

## Files in this folder

- `providers.tf`: provider setup + default tags
- `variables.tf`: region, instance_type, key path, SSH CIDR, name prefix
- `main.tf`: AMI lookup (AL2023), SG, key pair, EC2 + outputs
- `bootstrap-nginx.sh`: user-data script (nginx + hello page)
- `terraform.tfvars`: your IP (/32) and optional region/type overrides (created by you)
- `.gitignore`: ignores `.terraform`, state, plans, `tfvars`
- `README.md`: this file

---

## Variables & customization

- `region` (default: `us-east-2`)
- `instance_type` (default: `t3.micro`; use `t2.micro` if needed in your region)
- `key_public_path` (default: `~/.ssh/nebo_aws.pub`)
- `allowed_ssh_cidr` (**required**): your public IP in CIDR `/32`
- `name_prefix` (default: `nebo-lab`)

---

## Deploy 

```bash
# 1) Set your IP (/32) for SSH
MYIP=$(curl -s https://ifconfig.me || curl -s https://checkip.amazonaws.com)
echo "allowed_ssh_cidr = \"${MYIP}/32\"" > terraform.tfvars

# (Optional) pin region/type
cat >> terraform.tfvars << 'EOF'
region        = "us-east-2"
instance_type = "t3.micro"

# 2) Terraform workflow
terraform init
terraform validate
terraform plan -out plan.out
terraform apply "plan.out"
