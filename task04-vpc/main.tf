# Get AZs to place the subnet
data "aws_availability_zones" "available" {
  state = "available"
}

# 1) VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name_prefix}" }
}

# 2) Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

# 3) Public subnet (map public IPs on launch)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-1a" }
}

# 4) Public route table (send 0.0.0.0/0 to IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 5) NACL for the public subnet
# - Allow inbound 80, 22, and ephemeral ports for return traffic
# - Allow all outbound
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [aws_subnet.public.id]

  # Inbound HTTP 80
  ingress {
    rule_no    = 100
    protocol   = "6"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Inbound SSH 22 (from anywhere because SG will still lock to your IP;
  # you can change this to your IP/32 if you want to be stricter)
  ingress {
    rule_no    = 110
    protocol   = "6"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Inbound ephemeral (1024-65535) so responses work
  ingress {
    rule_no    = 120
    protocol   = "6"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: allow all
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = { Name = "${var.name_prefix}-nacl-public" }
}

# 6) Key Pair (import your public key)
resource "aws_key_pair" "this" {
  key_name   = "${var.name_prefix}-key"
  public_key = trimspace(file(var.key_public_path))
}

# 7) Security Group (instance-level)
# - SSH only from your IP
# - HTTP open
resource "aws_security_group" "web_ssh" {
  name        = "${var.name_prefix}-sg"
  description = "Instance-level: SSH from my IP, HTTP from all"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-sg" }
}

# 8) Find an AL2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 9) EC2 in the public subnet
resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_ssh.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.this.key_name

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf -y update || yum -y update || true
    dnf -y install nginx || yum -y install nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html><html><head><meta charset="utf-8"><title>NEBo VPC</title></head>
    <body><h1>NEBo VPC — Public Subnet</h1><p>Served by nginx.</p></body></html>
    HTML
    systemctl enable nginx
    systemctl start  nginx
  EOT

  tags = {
    Name = "${var.name_prefix}-web"
  }
}

output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet" { value = aws_subnet.public.id }
output "public_ip" { value = aws_instance.web.public_ip }
output "http_url" { value = "http://${aws_instance.web.public_ip}" }
