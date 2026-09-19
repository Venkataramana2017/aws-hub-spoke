output "transit_gateway_id" {
  value = module.tgw.id
}

output "vpc_ids" {
  value = { for name, vpc in module.vpc : name => vpc.id }
}

output "tgw_attachment_ids" {
  value = module.attachments.attachment_ids
}
