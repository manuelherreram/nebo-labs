# Task 06 — CloudWatch Observability (EC2 + CloudWatch Agent)

This lab demonstrates **observability** by launching (or reusing) an EC2 instance with:
- **nginx** serving a test page
- **CloudWatch Agent** sending metrics & logs
- A **CloudWatch Alarm** for CPU usage

---

## What you deploy

- **IAM role + instance profile** for CloudWatch Agent + SSM
- **CloudWatch Log Group**: `/nebo/nginx/access`
- **CloudWatch Alarm**: triggers if CPU > 60% for 5 minutes
- **Optional EC2 instance**:
  - Amazon Linux 2023, `t3.micro` (Free Tier eligible)
  - Security Group: SSH from *your IP only*, HTTP 80 open
  - Installed nginx + CloudWatch Agent via user-data

---

## Prerequisites

- AWS account, **IAM user** with CLI configured (`aws configure`)
- SSH key pair: `~/.ssh/nebo_aws(.pub)`
- Terraform >= 1.6 installed
- Public IP (used in `terraform.tfvars`)

---

## Files in this folder

- `providers.tf` → provider setup + tags  
- `variables.tf` → configurable inputs (region, CIDR, key path)  
- `main.tf` → IAM role, CloudWatch agent config, log group, alarm, optional EC2  
- `terraform.tfvars` → your SSH CIDR and overrides  
- `.gitignore` → ignores `.terraform`, states, tfvars  
- `README.md` → this file  

---

## Variables & customization

- `region` (default: `us-east-2`)  
- `instance_type` (default: `t3.micro`)  
- `key_public_path` (default: `~/.ssh/nebo_aws.pub`)  
- `allowed_ssh_cidr` (**required**) → `"YOUR_PUBLIC_IP/32"`  
- `existing_instance_id` (default: empty) → if set, skips creating a new instance  

---

## Usage

Initialize and deploy:

```bash
terraform init
terraform validate
terraform plan -out plan.out
terraform apply "plan.out"
```
Outputs:

- created_instance_id → if a demo instance was created

- log_group → /nebo/nginx/access

- alarm_name → CPU alarm name

## How to test
- Generate traffic

```bash
IP=$(aws ec2 describe-instances \
  --instance-ids "$(terraform output -raw created_instance_id)" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

for i in {1..20}; do curl -s "http://$IP" >/dev/null; done
```
## Check CloudWatch Logs

- Go to CloudWatch → Log groups → /nebo/nginx/access

- Look for a log stream named after the instance ID

## Check Metrics

- CloudWatch → Metrics → CWAgent: memory, disk, netstat

- CloudWatch → Metrics → EC2: CPUUtilization

## Check Alarm

- CloudWatch → Alarms → nebo-obs-cpu-high should be OK at rest

To trigger it:


```
ssh -i ~/.ssh/nebo_aws ec2-user@"$IP"
yes > /dev/null &
sleep 120
kill %1
``` 
## Cleanup
```
terraform destroy

##Troubleshooting
- No AMI found → ensure region supports AL2023 (us-east-2 works)

- SSH fails → check allowed_ssh_cidr matches your IP/32

- Logs missing → confirm /var/log/nginx/access.log exists and CloudWatch Agent is running

- Alarm not firing → generate CPU load longer (>5m)

## Mapping to program tasks
- Traffic control: SG locks SSH to your IP, opens HTTP

- Configure and use SSH access with imported key pair

- Observability: CloudWatch agent collects metrics/logs + alarm configured
