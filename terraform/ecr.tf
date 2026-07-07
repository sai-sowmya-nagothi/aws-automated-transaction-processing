resource "aws_ecr_repository" "transaction_processor" {
  name                 = "transaction-processor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "transaction-processor"
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

output "ecr_repository_url" {
  description = "ECR repository URL for the ECS transaction processor"
  value       = aws_ecr_repository.transaction_processor.repository_url
}
