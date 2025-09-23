terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Consistent tags across all resources (recommended pattern)
  # Docs: default_tags provider block
  default_tags {
    tags = {
      Project    = "nebo-labs"
      Environment = "lab"
      ManagedBy  = "terraform"
    }
  }
}

