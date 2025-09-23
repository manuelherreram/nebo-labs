variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  default     = "nebo-vpc"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "key_public_path" {
  description = "Path to your public SSH key"
  type        = string
  default     = "~/.ssh/nebo_aws.pub"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP /32 for SSH"
  type        = string
}

variable "instance_type" {
  description = "Instance size"
  type        = string
  default     = "t3.micro"
}
