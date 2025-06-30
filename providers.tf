terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# add s3 backed state
terraform {
  backend "s3" {
    bucket       = "epam-demo-terraform"
    key          = "epam-web-app/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }
}

        