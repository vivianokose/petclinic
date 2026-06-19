provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "petclinic"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}
