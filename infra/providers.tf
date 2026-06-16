provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "digilians-tfstate"
    key    = "digilians.tfstate" # تم تعديل الكومة بنقطة
    region = "eu-west-1"
  }
}