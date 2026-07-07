resource "aws_iam_role" "step_functions_role" {
  name = "transaction-processing-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "run-transaction-processor-ecs"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = aws_ecs_task_definition.transaction_processor.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "transaction_workflow" {
  name     = "transaction-processing-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  depends_on = [
    aws_iam_role_policy.step_functions_policy
  ]

  definition = jsonencode({
    Comment = "Process uploaded CSV files using ECS Fargate"
    StartAt = "ProcessCSV"

    States = {
      ProcessCSV = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"

        Parameters = {
          LaunchType = "FARGATE"

          Cluster = aws_ecs_cluster.transaction_processing.arn

          TaskDefinition = aws_ecs_task_definition.transaction_processor.arn

          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = [
                aws_subnet.public.id
              ]

              SecurityGroups = [
                aws_security_group.processing.id
              ]

              AssignPublicIp = "ENABLED"
            }
          }

          Overrides = {
            ContainerOverrides = [
              {
                Name = "transaction-processor"

                Environment = [
                  {
                    Name      = "S3_BUCKET"
                    "Value.$" = "$.bucket"
                  },
                  {
                    Name      = "S3_KEY"
                    "Value.$" = "$.key"
                  }
                ]
              }
            ]
          }
        }

        End = true
      }
    }
  })
}

resource "aws_iam_role" "eventbridge_step_functions_role" {
  name = "eventbridge-start-transaction-workflow"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_step_functions_policy" {
  name = "start-transaction-workflow"
  role = aws_iam_role.eventbridge_step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "states:StartExecution"
      Resource = aws_sfn_state_machine.transaction_workflow.arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "csv_uploaded" {
  name = "transaction-csv-uploaded"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]

    detail = {
      bucket = {
        name = [aws_s3_bucket.transaction_files.bucket]
      }

      object = {
        key = [{
          suffix = ".csv"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "start_transaction_workflow" {
  rule     = aws_cloudwatch_event_rule.csv_uploaded.name
  arn      = aws_sfn_state_machine.transaction_workflow.arn
  role_arn = aws_iam_role.eventbridge_step_functions_role.arn

  input_transformer {
    input_paths = {
      bucket = "$.detail.bucket.name"
      key    = "$.detail.object.key"
    }

    input_template = <<INPUT
{"bucket": <bucket>, "key": <key>}
INPUT
  }
}

