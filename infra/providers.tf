provider "aws" {
    region = "eu-west-1"
}

terraform {
  backend s3 {
    bucket = "digilians-tfstate"
    key = "digilians,tfstate"
    region = "eu-west-1"
    dynamodb_table = "YOUR_DYNAMODB_TABLE_NAME" // the denamodb name should write 
  } 
}