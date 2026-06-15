provider "aws" {
    region = "eu-west-1"
}

terraform {
  backend s3 {
    bucket = "digilians-tfstate"
    key = "digilians,tfstate"
    region = "eu-west-1"
    dynamodb_table = "esraa_trerraform_locks_digilians" 
  } 
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "esraa_trerraform_locks_digilians"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}