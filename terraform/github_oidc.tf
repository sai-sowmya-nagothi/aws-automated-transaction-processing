

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "github-actions-oidc"
  }
}

resource "aws_iam_role" "github_terraform_deployment" {
  name = "github-terraform-deployment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:sai-sowmya-nagothi/aws-automated-transaction-processing:ref:refs/heads/feature/ecs-processing"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "github-terraform-deployment-role"
    Purpose = "Single IAM role used by GitHub Actions for Terraform deployment"
  }
}


resource "aws_iam_role_policy_attachment" "github_terraform_admin" {
  role       = aws_iam_role.github_terraform_deployment.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


output "github_terraform_deployment_role_arn" {
  description = "IAM role assumed by GitHub Actions for Terraform deployment"
  value       = aws_iam_role.github_terraform_deployment.arn
}
