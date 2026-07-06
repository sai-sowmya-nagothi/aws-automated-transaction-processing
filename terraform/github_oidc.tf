# ============================================================
# GitHub OIDC Provider
# Allows GitHub Actions to authenticate to AWS without
# storing permanent AWS access keys in GitHub.
# ============================================================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "github-actions-oidc"
  }
}


# ============================================================
# Single IAM Role for GitHub-Based Infrastructure Deployment
#
# This is the ONE deployment role required by the assignment.
# GitHub Actions assumes this role and Terraform uses it to
# create/update the EC2 instance, ECS task definition, and
# the remaining project infrastructure.
# ============================================================

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


# ============================================================
# Deployment Permissions
#
# For the assignment implementation, the single GitHub role
# receives permission to deploy the AWS resources managed by
# this Terraform project.
# ============================================================

resource "aws_iam_role_policy_attachment" "github_terraform_admin" {
  role       = aws_iam_role.github_terraform_deployment.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# ============================================================
# Output
# Copy this ARN later into the GitHub Actions workflow.
# ============================================================

output "github_terraform_deployment_role_arn" {
  description = "IAM role assumed by GitHub Actions for Terraform deployment"
  value       = aws_iam_role.github_terraform_deployment.arn
}
