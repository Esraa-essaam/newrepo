variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "digilians-lnb"
}
variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}