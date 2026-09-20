locals {
  # Keep these non-overlapping with one another and with on-premises networks.
  networks = {
    hub     = { cidr = "10.0.0.0/16", role = "hub" }
    dev     = { cidr = "10.1.0.0/16", role = "spoke" }
    qa      = { cidr = "10.2.0.0/16", role = "spoke" }
    preprod = { cidr = "10.3.0.0/16", role = "spoke" }
    prod    = { cidr = "10.4.0.0/16", role = "spoke" }
    shared  = { cidr = "10.5.0.0/16", role = "spoke" }
    sandbox = { cidr = "10.6.0.0/16", role = "spoke" }
  }

  spokes = { for name, network in local.networks : name => network if network.role == "spoke" }
}

module "tgw" {
  source = "./modules/transit-gateway"
  name   = "platform"
}

module "vpc" {
  for_each = local.networks

  source = "./modules/vpc"

  name               = each.key
  cidr_block         = each.value.cidr
  availability_zones = var.availability_zones
  tgw_id             = module.tgw.id
  # Workloads can reach the central hub and shared tools, but not another workload VPC.
  tgw_destination_cidrs = each.key == "hub" ? [for network in values(local.spokes) : network.cidr] : each.key == "shared" ? [for name, network in local.networks : network.cidr if name != "shared"] : [local.networks.hub.cidr, local.networks.shared.cidr]
  enable_nat_gateway    = var.enable_nat_gateway
}

module "attachments" {
  source = "./modules/tgw-attachments"

  tgw_id = module.tgw.id
  attachments = {
    for name, vpc in module.vpc : name => {
      vpc_id     = vpc.id
      subnet_ids = vpc.tgw_subnet_ids
    }
  }
  # Source VPC => permitted destination VPCs. There is no Dev-to-Prod route.
  allowed_routes = {
    hub     = { for name, network in local.spokes : name => network.cidr }
    shared  = { for name, network in local.networks : name => network.cidr if name != "shared" }
    dev     = { hub = local.networks.hub.cidr, shared = local.networks.shared.cidr }
    qa      = { hub = local.networks.hub.cidr, shared = local.networks.shared.cidr }
    preprod = { hub = local.networks.hub.cidr, shared = local.networks.shared.cidr }
    prod    = { hub = local.networks.hub.cidr, shared = local.networks.shared.cidr }
    sandbox = { hub = local.networks.hub.cidr, shared = local.networks.shared.cidr }
  }
}
