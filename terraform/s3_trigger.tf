resource "aws_s3_bucket_notification" "transaction_upload" {
  bucket      = aws_s3_bucket.transaction_files.id
  eventbridge = true
}
