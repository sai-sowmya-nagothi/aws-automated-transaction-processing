resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transaction_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.transaction_files.arn
}

resource "aws_s3_bucket_notification" "transaction_upload" {
  bucket = aws_s3_bucket.transaction_files.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.transaction_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
