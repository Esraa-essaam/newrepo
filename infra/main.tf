# 1. الـ VPC الأساسي بناءً على الـ variables بتاعتك
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# 2. الـ Subnets اللي كان بيدور عليها ومش لاقيها
# resource "aws_subnet" "public1" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
#   availability_zone = "eu-west-1a"

#   tags = {
#     Name = "${var.vpc_name}-public-1"
#   }
# }

# resource "aws_subnet" "public2" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
#   availability_zone = "eu-west-1b"

#   tags = {
#     Name = "${var.vpc_name}-public-2"
#   }
# }

# # 3. الـ Security Group الخاص بالـ ALB
# resource "aws_security_group" "alb_sg" {
#   name        = "alb-security-group"
#   description = "Allow inbound HTTP traffic"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.vpc_name}-alb-sg"
#   }
# }

# # 4. Internet Gateway
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "main-igw"
#   }
# }

# # 5. Route Table & Route
# resource "aws_route_table" "rt" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "public-route-table"
#   }
# }

# resource "aws_route" "r" {
#   route_table_id         = aws_route_table.rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.gw.id
# }

# # 6. Route Table Associations
# resource "aws_route_table_association" "assoc_public1" {
#   subnet_id      = aws_subnet.public1.id
#   route_table_id = aws_route_table.rt.id
# }

# resource "aws_route_table_association" "assoc_public2" {
#   subnet_id      = aws_subnet.public2.id
#   route_table_id = aws_route_table.rt.id
# }

# # 7. Application Load Balancer (ALB)
# resource "aws_lb" "app_alb" {
#   name               = "app-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

#   tags = {
#     Environment = "production"
#   }
# }

# # 8. Target Group
# resource "aws_lb_target_group" "alb_tg" {
#   name     = "app-alb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id

#   health_check {
#     path                = "/"
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     timeout             = 5
#     interval            = 30
#     matcher             = "200"
#   }
# }

# # 9. EC2 security group for the web server
# resource "aws_security_group" "web_sg" {
#   name        = "web-server-sg"
#   description = "Allow HTTP traffic from the ALB"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.vpc_name}-web-sg"
#   }
# }

# 10. Amazon Linux 2 AMI lookup
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# 11. Web server EC2 instance
# resource "aws_instance" "web" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public1.id
#   associate_public_ip_address = true
#   vpc_security_group_ids = [aws_security_group.web_sg.id]
#   user_data              = templatefile("${path.module}/user_data.sh", {
#     html_content = file("${path.module}/index.html")
#   })

#   tags = {
#     Name = "${var.vpc_name}-web"
#   }
# }

# 12. Attach EC2 instance to ALB target group
# resource "aws_lb_target_group_attachment" "web_attachment" {
#   target_group_arn = aws_lb_target_group.alb_tg.arn
#   target_id        = aws_instance.web.id
#   port             = 80
# }

# # 13. ALB Listener
# resource "aws_lb_listener" "alb_listener" {
#   load_balancer_arn = aws_lb.app_alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.alb_tg.arn
#   }
# }

# 10. الـ DynamoDB table الخاص بالـ Locks
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "esraa_trerraform_locks_digilians"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }