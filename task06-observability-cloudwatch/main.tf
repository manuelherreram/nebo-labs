########################################
# Data: AZs + Amazon Linux 2023 AMI
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
# CloudWatch Agent IAM role/policy
########################################
data "aws_iam_policy_document" "cw_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cw_agent_role" {
  name               = "${var.name_prefix}-cw-agent-role"
  assume_role_policy = data.aws_iam_policy_document.cw_assume.json
}

resource "aws_iam_role_policy_attachment" "cw_agent_attach" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cw_agent_profile" {
  name = "${var.name_prefix}-cw-agent-profile"
  role = aws_iam_role.cw_agent_role.name
}

########################################
# CloudWatch Logs group for nginx access log
########################################
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/nebo/nginx/access"
  retention_in_days = 7
}

########################################
# Create or reuse an instance?
########################################
locals {
  create_instance = var.existing_instance_id == "" ? true : false
}

# Networking (only if creating the demo instance)
resource "aws_vpc" "vpc" {
  count                = local.create_instance ? 1 : 0
  cidr_block           = "10.6.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  count  = local.create_instance ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_subnet" "public" {
  count                   = local.create_instance ? 1 : 0
  vpc_id                  = aws_vpc.vpc[0].id
  cidr_block              = "10.6.1.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-a" }
}

resource "aws_route_table" "public" {
  count  = local.create_instance ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = local.create_instance ? 1 : 0
  route_table_id = aws_route_table.public[0].id
  subnet_id      = aws_subnet.public[0].id
}

resource "aws_security_group" "web_ssh" {
  count       = local.create_instance ? 1 : 0
  name        = "${var.name_prefix}-sg"
  description = "SSH from my IP; HTTP 80 from world"
  vpc_id      = aws_vpc.vpc[0].id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
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

resource "aws_key_pair" "this" {
  count      = local.create_instance ? 1 : 0
  key_name   = "${var.name_prefix}-key"
  public_key = trimspace(file(var.key_public_path))
}

########################################
# User data: install nginx + CloudWatch Agent with config
########################################
locals {
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf -y update || yum -y update || true
    dnf -y install nginx curl
    systemctl enable nginx
    systemctl start nginx

    # Install CloudWatch Agent
    CWBIN="amazon-cloudwatch-agent.rpm"
    curl -s -o /tmp/$CWBIN https://amazoncloudwatch-agent-us-east-1.s3.us-east-1.amazonaws.com/amazon_linux/amd64/latest/$CWBIN || true
    rpm -Uvh /tmp/$CWBIN || true

    # Agent config file (note $${aws:...} to avoid Terraform interpolation)
    cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
    {
      "agent": {
        "metrics_collection_interval": 60,
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/agent.log"
      },
      "metrics": {
        "append_dimensions": {
          "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
          "ImageId": "$${aws:ImageId}",
          "InstanceId": "$${aws:InstanceId}",
          "InstanceType": "$${aws:InstanceType}"
        },
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle","cpu_usage_user","cpu_usage_system"],
            "metrics_collection_interval": 60,
            "totalcpu": true
          },
          "mem": {
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60
          },
          "disk": {
            "measurement": ["used_percent"],
            "resources": ["*"],
            "ignore_file_system_types": ["sysfs","devtmpfs","proc","tmpfs"]
          },
          "netstat": {
            "measurement": ["tcp_established","tcp_time_wait"]
          },
          "statsd": {
            "service_address": ":8125",
            "metrics_aggregation_interval": 60
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/nginx/access.log",
                "log_group_name": "/nebo/nginx/access",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    JSON

    # Start agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  EOT
}

########################################
# If creating demo instance, launch it
########################################
resource "aws_instance" "web" {
  count                       = local.create_instance ? 1 : 0
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web_ssh[0].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.this[0].key_name
  iam_instance_profile        = aws_iam_instance_profile.cw_agent_profile.name
  user_data                   = local.user_data

  tags = { Name = "${var.name_prefix}-web" }
}

# Target instance ID (existing or created)
locals {
  target_instance_id = local.create_instance ? aws_instance.web[0].id : var.existing_instance_id
}

########################################
# CloudWatch Alarm: CPUUtilization > 60% for 5 min
########################################
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Average CPU > 60% for 5 minutes"
  dimensions = {
    InstanceId = local.target_instance_id
  }
}

########################################
# Outputs
########################################
output "created_instance_id" {
  value       = local.create_instance ? aws_instance.web[0].id : ""
  description = "If a new instance was created, its ID appears here"
}

output "log_group" {
  value = aws_cloudwatch_log_group.nginx.name
}

output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}
