variable "region" {
  type        = string
  description = "AWS Region for this landing-zone network."
  default     = "us-east-1"
}

variable "availability_zones" {
  type        = list(string)
  description = "Two or more AZs in the selected Region."
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create one NAT Gateway per VPC. Costs money; use false for a lab."
  default     = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all supported resources."
}
