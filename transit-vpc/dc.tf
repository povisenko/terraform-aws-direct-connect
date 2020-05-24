/**********************************************
 * Variables that should be distributed by your connection provider
***********************************************/
variable "bgp_provider_asn" {
  description = "BGP autonomous system number of the provider. Distributed by provider"
}
variable "provider_vln_id" {
  description = "BGP VLN ID of the provider. Distributed by provider"
}
variable "primary_bgp_key" {
  description = "BGP auth key for primary virtual interface. Distributed by provider"
}
variable "secondary_bgp_key" {
  description = "BGP auth key for secondary virtual interface. Distributed by provider"
}
variable "primary_connection_id" {
  description = "BGP auth key for primary virtual interface. Distributed by provider"
}
variable "secondary_connection_id" {
  description = "IP range distributed by provider"
}
variable "primary_amazon_address" {
  description = "IP range distributed by provider"
}
variable "secondary_amazon_address" {
  description = "IP range distributed by provider"
}
variable "primary_customer_address" {
  description = "IP range distributed by provider"
}
variable "secondary_customer_address" {
  description = "IP range distributed by provider"
}

/**********************************************
 * Direct connect gateway for provider network
***********************************************/

resource "aws_dx_gateway" "provider-gateway" {
  name            = "provider-dc-gateway"
  amazon_side_asn = "64512" // usually it's a default value
}

resource "aws_dx_gateway_association" "transit" {
  dx_gateway_id         = aws_dx_gateway.provider-gateway.id
  associated_gateway_id = aws_vpn_gateway.transit_vpn_gw.id
  allowed_prefixes = [
    var.transit_vpc_cidr
  ]
}

/**********************************************
 * Virtual interfaces attached to the provider gateway
 * all inner properties were taken from spreadsheet
 * distributed by provider
***********************************************/

resource "aws_dx_private_virtual_interface" "primary" {
  connection_id    = var.primary_connection_id
  name             = "provider-vif-primary"
  vlan             = var.provider_vln_id
  address_family   = "ipv4"
  bgp_asn          = var.bgp_provider_asn
  amazon_address   = var.primary_amazon_address
  customer_address = var.primary_customer_address
  dx_gateway_id    = aws_dx_gateway.provider-gateway.id
  bgp_auth_key     = var.primary_bgp_key

}

resource "aws_dx_private_virtual_interface" "secondary" {
  connection_id    = var.secondary_connection_id
  name             = "provider-vif-secondary"
  vlan             = var.provider_vln_id
  address_family   = "ipv4"
  bgp_asn          = var.bgp_provider_asn
  amazon_address   = var.secondary_amazon_address
  customer_address = var.secondary_customer_address
  dx_gateway_id    = aws_dx_gateway.provider-gateway.id
  bgp_auth_key     = var.secondary_bgp_key
}