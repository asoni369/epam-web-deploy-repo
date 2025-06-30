module "vpc" {
  source     = "terraform-aws-modules/vpc/aws"
  version    = "5.21.0"
  name       = "custom-epam-vpc"
  cidr       = "10.0.0.0/16"
  create_igw = true
  azs        = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = local.common_tags
}