########################################
# AMI + AZ
########################################
data "aws_availability_zones" "azs" {
  state = "available"
}

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

########################################
# Networking: VPC + public subnet + IGW
########################################
resource "aws_vpc" "vpc" {
  cidr_block           = "10.7.0.0/16"
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
  cidr_block              = "10.7.1.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-a" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

########################################
# Security Group: SSH from YOUR IP; 8080 open
########################################
resource "aws_security_group" "web_ssh" {
  name        = "${var.name_prefix}-sg"
  description = "SSH from my IP; HTTP 8080 from world"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description      = "HTTP 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-sg" }
}

########################################
# Key Pair + EC2
########################################
resource "aws_key_pair" "kp" {
  key_name   = "${var.name_prefix}-key"
  public_key = trimspace(file(var.key_public_path))
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_ssh.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.kp.key_name

  tags = { Name = "${var.name_prefix}-web" }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
