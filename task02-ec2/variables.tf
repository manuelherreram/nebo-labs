variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "Free Tier eligible in many regions (t3.micro). If t3 not available, try t2.micro."
  type        = string
  default     = "t3.micro"
}

variable "key_public_path" {
  description = "Path to your local public key to import as an AWS key pair"
  type        = string
  default     = "~/.ssh/nebo_aws.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH (YOUR public IP/32)"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "nebo-lab"
}
