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
  name = "invoke-transaction-processor"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.transaction_processor.arn
    }]
  })
}

resource "aws_sfn_state_machine" "transaction_workflow" {
  name     = "transaction-processing-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Automatically process uploaded transaction CSV files"
    StartAt = "ProcessCSV"

    States = {
      ProcessCSV = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        OutputPath = "$.Payload"

        Parameters = {
          FunctionName = aws_lambda_function.transaction_processor.arn
          "Payload.$"  = "$"
        }

        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2
        }]

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
