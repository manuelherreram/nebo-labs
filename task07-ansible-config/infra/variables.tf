variable "region" {
  type    = string
  default = "us-east-2"
}

variable "name_prefix" {
  type    = string
  default = "nebo-ansible"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_public_path" {
  type    = string
  default = "~/.ssh/nebo_aws.pub"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Your public IP/32 for SSH"
}
