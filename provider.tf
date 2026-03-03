terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Specifies the source of the AWS provider
      version = "~> 6.0" # Constrains the version to minor releases of 6.x

    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"  # Explicitly sets the AWS region for resource creation
}

