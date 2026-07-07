terraform {
  backend "s3" {
    bucket  = "aws-transaction-terraform-state-265145884274"
    key     = "transaction-processing/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
