variable "region" {
  type    = string
  default = "us-east-2"
}

variable "name_prefix" {
  type    = string
  default = "nebo-obs"
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
  description = "Your public IP /32 for SSH when creating the demo instance"
  type        = string
}

# If you have an existing instance to instrument, set this to its ID.
# If empty, Terraform will create a demo instance for you.
variable "existing_instance_id" {
  type        = string
  default     = ""
  description = "Optional: existing EC2 instance ID to attach agent to"
}
