# GitHub Actions OIDC bootstrap

This stack creates the GitHub OIDC provider and a role trusted by any
repository and branch except `main` under `github_organization`. The default
owner is `Venkataramana2017`; change it when bootstrapping another owner. It
creates a dedicated `github-actions-aws-hub-spoke-terraform` role.

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

Create GitHub Environments named `terraform-plan` and `terraform-changes`, and
configure required reviewers on both. Plans, applies, and destroys pause until
the selected environment is approved. Every repository using this role must
copy this workflow and configure its own `AWS_ROLE_ARN` secret.

Do not use the existing `github-terraform-actions` role for this repository.
That role is trusted by a different repository (`aws-devops-terraform`) and
will fail with `Not authorized to perform sts:AssumeRoleWithWebIdentity`.
The `AWS_ROLE_ARN` secret must be set to the output from this bootstrap stack:

```powershell
terraform output -raw github_actions_role_arn
```

If the workflow already exists but OIDC is denied, run `terraform apply` here
again after pulling the latest bootstrap changes, then update `AWS_ROLE_ARN`
with the output value.

The bootstrap stack uses local state. Keep its generated `terraform.tfstate`
file secure and do not commit it.
