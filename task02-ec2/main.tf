# Find latest Amazon Linux 2023 (x86_64) in this region
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

# Import your SSH public key as a Key Pair
resource "aws_key_pair" "this" {
  key_name   = "${var.name_prefix}-key"
  public_key = trimspace(file(var.key_public_path))
}

# SG: allow SSH only from your IP; allow HTTP from anywhere
resource "aws_security_group" "web_ssh" {
  name        = "${var.name_prefix}-sg"
  description = "Allow SSH from my IP and HTTP from anywhere"

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
}

# EC2 instance with user-data to install nginx and serve a page
resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_ssh.id]
  key_name               = aws_key_pair.this.key_name
  user_data              = file("${path.module}/bootstrap-nginx.sh")

  tags = {
    Name = "${var.name_prefix}-web"
    Task = "task02-ec2"
  }
}

output "public_ip"  { value = aws_instance.web.public_ip }
output "public_dns" { value = aws_instance.web.public_dns }
output "http_url"   { value = "http://${aws_instance.web.public_ip}" }
