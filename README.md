# AWS Hub-and-Spoke Terraform starter

This is a reusable single-account, single-region foundation for the network shown in your diagram. It creates:

- A hub VPC and Dev, QA, Pre-Prod, Prod, Shared Services, and Sandbox spoke VPCs
- Private and public subnets across two Availability Zones
- One Transit Gateway (TGW) and VPC attachments
- A separate TGW route table per spoke so spokes cannot communicate with each other
- Routes between each spoke and the hub/shared network

## Before applying

1. Install Terraform and configure AWS credentials for the target account.
2. Optionally override the default region, Availability Zones, CIDRs, and tags
   in `terraform.tfvars` (copy from `terraform.tfvars.example`).
3. Review the CIDR ranges against your corporate/on-premises network; no ranges may overlap.
4. Initialize the S3 backend. It uses the configured S3 state bucket and an S3
   lockfile; no DynamoDB table is required:

```powershell
terraform init
```

5. Then run:

```powershell
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## Manual GitHub Actions workflow

`.github/workflows/terraform.yml` automatically runs `terraform plan` when a
commit is pushed to `feature-*`, `feature/<name>`, `dev`, `dev-*`, or
`dev/<name>`. It also provides a manual **Terraform** workflow for `plan`,
`apply`, or `destroy`; `apply` and `destroy` require the `terraform-changes`
environment. It uses AWS OIDC rather
than long-lived AWS access keys and remote state so separate GitHub-hosted
runners use the same state.

Before its first use, configure these GitHub repository or environment settings:

- Variable `AWS_REGION`, for example `us-east-1`.
- Variable `TF_AVAILABILITY_ZONES`, as a Terraform list, for example
  `["us-east-1a", "us-east-1b"]`.
- Secret `AWS_ROLE_ARN`, the ARN of an AWS IAM role trusted by this repository's
  GitHub Actions OIDC provider. Grant the role only the permissions needed for
  this Terraform configuration.

The [`bootstrap`](bootstrap/README.md) stack creates the GitHub OIDC provider
and trusted role. Apply it once with AWS administrator credentials, then save
its `github_actions_role_arn` output as the `AWS_ROLE_ARN` secret.

Create `terraform-plan` and `terraform-changes` GitHub Environments. Configure
required reviewers on `terraform-changes` to require approval before `apply` or
`destroy`; leave `terraform-plan` unprotected if plans should run immediately.

## Traffic policy implemented

`Prod`, `Dev`, `QA`, `Pre-Prod`, and `Sandbox` each get a dedicated TGW route table with one route: Hub VPC. The Hub attachment uses its own route table and has routes to each spoke. This supports central services such as DNS, inspection, CI/CD, and internal APIs while preventing direct spoke-to-spoke access.

This starter intentionally does **not** expose workloads publicly or create EKS, RDS, CloudFront, WAF, Route 53 zones, Network Firewall, VPN/Direct Connect, or an ALB. Add those only with a concrete application design. In a production multi-account setup, share TGW through AWS Resource Access Manager and deploy a spoke attachment per account.

## Inspection caveat

The routing below centralizes connectivity but does not itself force every packet through AWS Network Firewall. To add inspection, create dedicated TGW route tables and firewall endpoint routes in the hub VPC, then replace the spoke-to-hub routes with routes to the inspection path. This avoids accidental asymmetric routing.
