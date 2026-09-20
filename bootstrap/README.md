# GitHub Actions OIDC bootstrap

This stack creates the GitHub OIDC provider and a role trusted by the
repository's `terraform-plan` and `terraform-changes` environments. It allows
only `feature-*`, `feature/<name>`, `dev`, `dev-*`, and `dev/<name>` branches.
It creates a dedicated `github-actions-aws-hub-spoke-terraform` role and does
not modify roles used by other repositories or pipelines.

Run it once with administrator credentials in AWS account `313932316713`:

```powershell
Set-Location bootstrap
terraform init
terraform apply
```

If the account already has the GitHub OIDC provider, use its ARN rather than
creating a duplicate:

```powershell
terraform apply `
  -var="create_oidc_provider=false" `
  -var="github_oidc_provider_arn=arn:aws:iam::313932316713:oidc-provider/token.actions.githubusercontent.com"
```

Copy the `github_actions_role_arn` output to the `AWS_ROLE_ARN` GitHub Actions
secret. Attach a least-privilege permissions policy to the created role that
allows Terraform to access the state bucket and manage the resources in the
main stack.

If the workflow already exists but OIDC is denied, run `terraform apply` here
again after pulling the latest bootstrap changes, then update `AWS_ROLE_ARN`
with the output value.

The bootstrap stack uses local state. Keep its generated `terraform.tfstate`
file secure and do not commit it.
