
resource "aws_vpc" "lnb_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "lnb_igw" {
  vpc_id = aws_vpc.lnb_vpc.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Public Subnet 1 (AZ: a)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.lnb_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true 

  tags = {
    Name = "${var.vpc_name}-public-1"
  }
}

# Public Subnet 2 (AZ: b)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.lnb_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true 

  tags = {
    Name = "${var.vpc_name}-public-2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lnb_vpc.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# الـ Route اللي بيطلع للإنترنت
resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lnb_igw.id
}

# ربط الـ Subnets بالـ Route Table (بدل الـ Gateway اللي كان في كودك القديم)
resource "aws_route_table_association" "association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}



# LB Security Group (يسمح بـ HTTP من أي مكان)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.lnb_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Security Group (يسمح فقط من الـ ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow inbound traffic from ALB only"
  vpc_id      = aws_vpc.lnb_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # الربط بالـ ALB SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "web_alb" {
  name               = "lnb-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_lb_target_group" "web_tg" {
  name        = "lnb-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.lnb_vpc.id
  target_type = "instance"

  health_check {
    path                = "/index.html"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


resource "aws_launch_template" "web_lt" {
  name_prefix   = "lnb-web-template-"
  image_id      = "ami-0c55b159cbfafe1f0" # ملحوظة: تأكدي إن الـ AMI دي لـ Amazon Linux 2023 في زون eu-west-1
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  metadata_options {
    http_tokens = "required" # تفعيل IMDSv2 إجباري للتاسك
  }

  # حقن ملفات السكريبت والـ HTML
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    html_content = file("${path.module}/index.html")
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                = "lnb-web-asg"
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.web_tg.arn]
  
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }
}