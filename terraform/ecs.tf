resource "aws_ecs_cluster" "transaction_processing" {
  name = "transaction-processing-cluster"

  tags = {
    Name      = "transaction-processing-cluster"
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

resource "aws_cloudwatch_log_group" "ecs_processor" {
  name              = "/ecs/transaction-processor"
  retention_in_days = 7

  tags = {
    Name      = "transaction-processor-logs"
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "transaction-processing-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "transaction-processing-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "transaction-processing-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.transaction_files.arn}/*"
      },
      {
        Effect = "Allow"

        Action = [
          "dynamodb:PutItem"
        ]

        Resource = aws_dynamodb_table.transactions.arn
      }
    ]
  })
}

resource "aws_ecs_task_definition" "transaction_processor" {
  family                   = "transaction-processor"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "transaction-processor"
      image     = "${aws_ecr_repository.transaction_processor.repository_url}:latest"
      essential = true

      environment = [
        {
          name  = "DYNAMODB_TABLE"
          value = aws_dynamodb_table.transactions.name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_processor.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy,
    aws_cloudwatch_log_group.ecs_processor
  ]

  tags = {
    Name      = "transaction-processor"
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS transaction processing cluster"
  value       = aws_ecs_cluster.transaction_processing.arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS transaction processor task definition"
  value       = aws_ecs_task_definition.transaction_processor.arn
}

