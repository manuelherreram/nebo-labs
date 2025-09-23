variable "region" {
  type    = string
  default = "us-east-2"
}

variable "name_prefix" {
  type    = string
  default = "nebo-priv"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "private_cidr" {
  type    = string
  default = "10.1.2.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_public_path" {
  description = "ED25519 public key for Linux/Bastion"
  type        = string
  default     = "~/.ssh/nebo_aws.pub"
}

variable "windows_key_public_path" {
  description = "RSA public key for Windows"
  type        = string
  default     = "~/.ssh/nebo_aws_rsa.pub"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP /32 (only you SSH to bastion)"
  type        = string
}
