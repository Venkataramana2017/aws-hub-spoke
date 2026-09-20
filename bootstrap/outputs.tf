output "github_actions_role_arn" {
  description = "Set this value as the AWS_ROLE_ARN GitHub Actions secret."
  value       = aws_iam_role.github_actions_terraform.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider trusted by the role."
  value       = local.github_oidc_provider_arn
}
