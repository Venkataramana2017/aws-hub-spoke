variable "tgw_id" { type = string }
variable "attachments" {
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))
}
variable "allowed_routes" {
  type        = map(map(string))
  description = "Source attachment => destination attachment => destination CIDR."
}

locals {
  route_pairs = merge([
    for source, destinations in var.allowed_routes : {
      for destination, cidr in destinations : "${source}-${destination}" => {
        source      = source
        destination = destination
        cidr        = cidr
      }
    }
  ]...)
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.attachments

  transit_gateway_id                              = var.tgw_id
  vpc_id                                          = each.value.vpc_id
  subnet_ids                                      = each.value.subnet_ids
  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = { Name = "${each.key}-tgw-attachment" }
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = var.attachments
  transit_gateway_id = var.tgw_id
  tags               = { Name = "${each.key}-tgw-rt" }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = var.attachments

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.key].id
}

resource "aws_ec2_transit_gateway_route" "allowed" {
  for_each = local.route_pairs

  destination_cidr_block         = each.value.cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.value.destination].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.source].id
}

output "attachment_ids" {
  value = { for name, attachment in aws_ec2_transit_gateway_vpc_attachment.this : name => attachment.id }
}
