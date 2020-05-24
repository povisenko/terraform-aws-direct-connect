variable "transit_vpc_name" {
  default = "transit-vpc"
}
variable "transit_vpc_cidr" {
  description = "Transit VPC CIDR. Your unique IP range in the network e.g. 10.10.14.0/24"
}
variable "transit_private_subnet" {
  description = "Transit VPC private subnet e.g 10.10.14.0/25"
}
variable "transit_public_subnet" {
  description = "Transit VPC public subnet for the NAT gateway e.g. 10.10.14.128/25"
}
variable "network_dns_server" {
  description = "IP of one of DNS servers in the network. Distributed by provider"
}
variable "network_dns_server_2" {
  description = "IP of one of DNS servers in the network. Distributed by provider"
}
variable "dhcp_options_domain_name" {
  description = "DHCP option domain name depending on your AWS region e.g. {your_region}.compute.internal"
}

/**********************************************
 * Transit-VPC
***********************************************/

module "transit-vpc" {
  version = "~> v2.0"
  source  = "terraform-aws-modules/vpc/aws"
  name    = var.transit_vpc_name
  cidr    = var.transit_vpc_cidr

  azs = [
    local.main_vpc_az,
  ]

  private_subnets = [
    var.transit_private_subnet,
  ]

  public_subnets = [
    var.transit_public_subnet,
  ]

  single_nat_gateway               = true
  one_nat_gateway_per_az           = false
  enable_nat_gateway               = true
  enable_vpn_gateway               = false
  enable_dhcp_options              = true
  dhcp_options_domain_name         = var.dhcp_options_domain_name
  dhcp_options_domain_name_servers = [var.network_dns_server, var.network_dns_server_2]


  tags = {
    Terraform = "true"
  }
}

resource "aws_vpc_peering_connection" "main-to-transit" {
  peer_vpc_id = module.transit-vpc.vpc_id
  vpc_id      = local.main_vpc_id
  auto_accept = true

  tags = {
    Name = "VPC Peering between main and transit VPC"
  }
}

resource "aws_route" "from-main-to-transit" {
  route_table_id            = local.main_private_routing_table
  destination_cidr_block    = var.transit_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main-to-transit.id
}
resource "aws_route" "from-main-public-to-transit" {
  route_table_id            = local.main_public_routing_table
  destination_cidr_block    = var.transit_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main-to-transit.id
}


resource "aws_route" "from-transit-to-main" {
  route_table_id            = module.transit-vpc.private_route_table_ids.0
  destination_cidr_block    = local.main_vpc_range
  vpc_peering_connection_id = aws_vpc_peering_connection.main-to-transit.id
}


/**********************************************
 * VPN Gateway in transit VPC and attachments
***********************************************/

resource "aws_vpn_gateway" "transit_vpn_gw" {
  tags = {
    Name = "transit-vpn-gw"
  }
}

resource "aws_vpn_gateway_attachment" "vpn_attachment" {
  vpc_id         = module.transit-vpc.vpc_id
  vpn_gateway_id = aws_vpn_gateway.transit_vpn_gw.id
}

resource "aws_vpn_gateway_route_propagation" "transit" {
  vpn_gateway_id = aws_vpn_gateway.transit_vpn_gw.id
  route_table_id = module.transit-vpc.private_route_table_ids.0
}

/**********************************************
 * Security group to allow SSH and HTTP from main VPC
***********************************************/

resource "aws_security_group" "transit_vpc_sg" {
  name        = "transit-vpc-sg"
  description = "Transit VPC SG"
  vpc_id      = module.transit-vpc.vpc_id

  ingress {
    description = "Allow SSH from main VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.main_vpc_range]
  }

  ingress {
    description = "Allow HTTP from main VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.main_vpc_range]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "transit-vpc"
  }
}