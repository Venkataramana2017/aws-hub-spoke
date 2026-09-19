variable "name" { type = string }
variable "cidr_block" { type = string }
variable "availability_zones" { type = list(string) }
variable "tgw_id" { type = string }
variable "tgw_destination_cidrs" { type = list(string) }
variable "enable_nat_gateway" { type = bool }

locals {
  az_count = length(var.availability_zones)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-public-${count.index + 1}", Tier = "public" }
}

resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 10)
  tags              = { Name = "${var.name}-private-${count.index + 1}", Tier = "private" }
}

# TGW attachments must use one subnet in every AZ that needs TGW access.
resource "aws_subnet" "tgw" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 20)
  tags              = { Name = "${var.name}-tgw-${count.index + 1}", Tier = "transit-gateway" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Cost-saving option: one NAT Gateway per VPC. For production HA, use one per AZ
# and send each private subnet to its local NAT Gateway.
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.this]
  tags          = { Name = "${var.name}-nat" }
}

resource "aws_route_table" "private" {
  count  = local.az_count
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private-rt-${count.index + 1}" }
}

resource "aws_route" "private_to_tgw" {
  for_each = { for pair in setproduct(range(local.az_count), var.tgw_destination_cidrs) : "${pair[0]}-${pair[1]}" => pair }

  route_table_id         = aws_route_table.private[each.value[0]].id
  destination_cidr_block = each.value[1]
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "private_to_internet" {
  for_each = var.enable_nat_gateway ? { for index in range(local.az_count) : tostring(index) => index } : {}

  route_table_id         = aws_route_table.private[each.value].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count          = local.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "tgw" {
  count          = local.az_count
  subnet_id      = aws_subnet.tgw[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

output "id" { value = aws_vpc.this.id }
output "tgw_subnet_ids" { value = aws_subnet.tgw[*].id }
