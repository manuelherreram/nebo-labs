# Task 04/05 — VPC + Traffic Control (SG & NACL)

Creates a VPC with a public subnet, Internet Gateway, route table, Network ACL, Security Group, and an EC2 instance (AL2023) that serves a test page via nginx.

## What this deploys
- VPC + Public Subnet (map public IPs)
- Internet Gateway + Public Route Table (0.0.0.0/0 and ::/0)
- NACL (ingress allow 22, 80, 1024–65535; egress allow all)
- Security Group (SSH from your IP/32; HTTP 80 open)
- EC2 (AL2023) with user-data to install nginx and write a page

## Outputs
- `vpc_id`, `public_subnet`, `public_ip`, `http_url`

## Test
```
curl $(terraform output -raw http_url)
ssh -i ~/.ssh/nebo_aws ec2-user@$(terraform output -raw public_ip)
```

## Clean up
```       
terraform destroy
```

