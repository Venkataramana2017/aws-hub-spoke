data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

locals {
  github_oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github_actions[0].arn : var.github_oidc_provider_arn
  github_repository        = "${var.github_organization}/${var.github_repository}"
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Environment jobs use environment subjects. The workflow branch guard
    # rejects main before credentials are requested.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_organization}/*:environment:*",
        "repo:${var.github_organization}@*/*@*:environment:*",
      ]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_organization}/*:ref:refs/heads/*",
        "repo:${var.github_organization}@*/*@*:ref:refs/heads/*",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:ref"
      values   = ["refs/heads/*"]
    }

    condition {
      test     = "StringNotLike"
      variable = "token.actions.githubusercontent.com:ref"
      values   = ["refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}
