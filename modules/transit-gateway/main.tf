variable "name" { type = string }

resource "aws_ec2_transit_gateway" "this" {
  description                     = "${var.name} central network hub"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = { Name = "${var.name}-tgw" }
}

output "id" { value = aws_ec2_transit_gateway.this.id }
