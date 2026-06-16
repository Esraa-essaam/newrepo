provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "digilians-tfstate"
    key    = "digilians.tfstate" # تم تعديل الكومة بنقطة
    region = "eu-west-1"
  }
}
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}