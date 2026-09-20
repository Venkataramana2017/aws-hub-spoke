variable "region" {
  type        = string
  description = "Region used by the AWS provider while creating IAM resources."
  default     = "us-east-1"
}

variable "github_organization" {
  type        = string
  description = "GitHub organization or user that owns the repository."
  default     = "Venkataramana2017"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository allowed to assume the CI role."
  default     = "aws-hub-spoke"
}

variable "role_name" {
  type        = string
  description = "Name for the dedicated aws-hub-spoke GitHub Actions OIDC role."
  default     = "github-actions-aws-hub-spoke-terraform"
}

variable "create_oidc_provider" {
  type        = bool
  description = "Create the GitHub OIDC provider. Set false if it already exists in this AWS account."
  default     = true
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub OIDC provider ARN when create_oidc_provider is false."
  default     = null
  nullable    = true

  validation {
    condition     = var.create_oidc_provider || var.github_oidc_provider_arn != null
    error_message = "github_oidc_provider_arn must be set when create_oidc_provider is false."
  }
}
