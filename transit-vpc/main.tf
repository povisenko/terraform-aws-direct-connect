//the same as in ../main.tf
provider "aws" {
  profile = "your-profile"
  region  = "your-region"
}

terraform {
  backend "s3" {
    bucket  = "your-terraform-states-bucket" //the same as in ../main.tf
    key     = "transit-vpc/terraform.tfstate"
    profile = "your-profile" //the same as in ../main.tf
    region  = "your-region"  //the same as in ../main.tf
  }
}

//the same as in ../main.tf
data "terraform_remote_state" "main" {
  backend = "s3"

  config = {
    bucket  = "your-terraform-states-bucket"
    key     = "terraform.tfstate"
    profile = "your-profile"
    region  = "your-region"
  }
}

/*********************************************************************************************************
locals here are linked to output variables in teh end of ../main.tf file that defiles main VPC configuration
**********************************************************************************************************/
locals {
  main_private_routing_table = data.terraform_remote_state.main.outputs.main_private_routing_table_id
  main_public_routing_table  = data.terraform_remote_state.main.outputs.main_public_routing_table_id
  main_vpc_id                = data.terraform_remote_state.main.outputs.main_vpc_id
  main_vpc_range             = data.terraform_remote_state.main.outputs.main_vpc_range
  main_vpc_az                = data.terraform_remote_state.main.outputs.main_vpc_az
  main_vpc_key_name          = data.terraform_remote_state.main.outputs.main_vpc_key_name
}