/************************************************************************
Code bellow is just an approximation of your potential VPC configuration in Terraform
It's used just to show the link with Transit VPC. Its configuration is located
in transit-vpc/ folder
************************************************************************/
variable "main_vpc_name" {
  description = "Name of your main VPC"
}
variable "main_vpc_cidr" {
  description = "CIDR of your main VPC, e.g. 10.1.0.0/16"
}
variable "public_subnet" {
  description = "pubic subnet of your main VPC (if you have), e.g. 10.1.1.0/24"
}
variable "private_app_subnet" {
  description = "private subnet of your main VPC (if you have), e.g. 10.1.2.0/24"
}
variable "main_vpc_key_name" {
  default     = "main-vpc-key"
  description = "Name of SSH key of your main VPC"
}
variable "aws_availability_zone" {
  description = "Your AWS AZ of your main VPC"
}

provider "aws" {
  profile = "your-profile"
  region  = "your-region"
}

terraform {
  backend "s3" {
    bucket  = "your-terraform-states-bucket"
    key     = "terraform.tfstate"
    profile = "your-profile"
    region  = "your-region"
  }
}

module "vpc" {
  version = "~> v2.0"
  source  = "terraform-aws-modules/vpc/aws"
  name    = var.main_vpc_name
  cidr    = var.main_vpc_cidr

  azs = [
    var.aws_availability_zone,
  ]

  private_subnets = [
    var.private_app_subnet
  ]

  public_subnets = [
    var.public_subnet,
  ]

  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_nat_gateway     = true
  enable_vpn_gateway     = false

  tags = {
    Terraform = "true"
  }
}

/***********************************************************************
bellow could be defined any other resources from you infrastructure
e.g. OpenVPN server, instances, security configuration, key pairs etc.

...
***********************************************************************/

resource "aws_key_pair" "key_pair" {
  key_name   = var.main_vpc_key_name
  public_key = file("${path.module}/${var.main_vpc_key_name}.pub")
}

/************************************************************************
Output variable that are used by transit VPC configuration under transit-vpc/ dir
************************************************************************/
output "main_vpc_id" {
  value = module.vpc.vpc_id
}

output "main_vpc_range" {
  value = module.vpc.vpc_cidr_block
}

output "main_vpc_az" {
  value = module.vpc.azs.0
}

output "main_vpc_key_name" {
  value = var.main_vpc_key_name
}

output "main_public_routing_table_id" {
  value = module.vpc.public_route_table_ids.0
}

output "main_private_routing_table_id" {
  value = module.vpc.private_route_table_ids.0
}
