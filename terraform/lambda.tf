data "archive_file" "lambda_processor" {
  type        = "zip"
  source_file = "${path.module}/../lambda/processor.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_processor" {
  name = "transaction-lambda-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name = "lambda-dynamodb-access"
  role = aws_iam_role.lambda_processor.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]

        Resource = aws_dynamodb_table.transactions.arn
      }
    ]
  })
}

resource "aws_lambda_function" "transaction_processor" {
  function_name = "transaction-processor"
  role          = aws_iam_role.lambda_processor.arn
  handler       = "processor.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_processor.output_path
  source_code_hash = data.archive_file.lambda_processor.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.transactions.name
    }
  }
}


resource "aws_iam_role_policy" "lambda_s3_read_access" {
  name = "lambda-s3-read-access"
  role = aws_iam_role.lambda_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.transaction_files.arn}/*"
      }
    ]
  })
}
