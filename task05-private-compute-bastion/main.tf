########################################
# Data lookups (AZs and AMIs)
########################################
data "aws_availability_zones" "azs" {
  state = "available"
}

# Amazon Linux 2023 (x86_64)
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

# Windows Server 2025 English Full Base (x86_64)
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

########################################
# Networking
########################################
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_cidr
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-a" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_cidr
  availability_zone = data.aws_availability_zones.azs.names[0]
  tags              = { Name = "${var.name_prefix}-private-a" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

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
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.name_prefix}-rt-private" }
}

resource "aws_route_table_association" "private_assoc" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private.id
}

########################################
# Security Groups
########################################
# Bastion: SSH only from your IP
resource "aws_security_group" "bastion_sg" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "SSH from my IP"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-bastion-sg" }
}

# Private Linux: SSH only from bastion SG
resource "aws_security_group" "linux_sg" {
  name        = "${var.name_prefix}-linux-sg"
  description = "SSH only from bastion"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "SSH from bastion SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-linux-sg" }
}

# Private Windows: RDP only from bastion SG
resource "aws_security_group" "windows_sg" {
  name        = "${var.name_prefix}-windows-sg"
  description = "RDP only from bastion"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "RDP from bastion SG"
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-windows-sg" }
}

########################################
# Key Pairs (ED25519 for Linux/Bastion; RSA for Windows)
########################################
resource "aws_key_pair" "kp" {
  key_name   = "${var.name_prefix}-key"
  public_key = trimspace(file(var.key_public_path))
}

resource "aws_key_pair" "kp_windows" {
  key_name   = "${var.name_prefix}-key-windows"
  public_key = trimspace(file(var.windows_key_public_path))
}

########################################
# Instances
########################################
# Bastion (public)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.kp.key_name

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf -y update || yum -y update || true
    dnf -y install tcpdump bind-utils iproute || true
  EOT

  tags = { Name = "${var.name_prefix}-bastion" }
}

# Linux (private)
resource "aws_instance" "linux" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.linux_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.kp.key_name
  tags                        = { Name = "${var.name_prefix}-linux" }
}

# Windows (private) — 2025
resource "aws_instance" "windows" {
  ami                         = data.aws_ami.windows.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.windows_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.kp_windows.key_name
  tags                        = { Name = "${var.name_prefix}-windows" }
}

########################################
# Outputs
########################################
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "linux_private_ip" {
  value = aws_instance.linux.private_ip
}

output "windows_private_ip" {
  value = aws_instance.windows.private_ip
}

output "windows_instance_id" {
  value = aws_instance.windows.id
}
