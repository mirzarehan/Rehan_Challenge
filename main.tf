variable "key_path" { 
  
  default = "/users/rehanbaig/.ssh/id_rsa.pub"
  }

variable "localip" {

  default = "0.0.0.0/0"
}
  




provider "aws" {
  region  = "us-east-1"
  profile = "rehan"
  }

 resource "aws_key_pair" "rehan1" {
    key_name   = "rehan1"
    public_key = "${file(var.key_path)}"
    }

resource "aws_default_vpc" "default" {
  tags {
    Name = "Default VPC"
  }
}
  resource "aws_security_group" "rehan_sg" {
    name        = "rehan_dev_sg"
    description = "Used for access to the dev instance"
  vpc_id = "${aws_default_vpc.default.id}"

  
  
  #HTTP

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    from_port   = 443
    to_port     = 443
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
   resource "aws_security_group" "rehan_lbonly-sg" {
    name        = "rehan_lb_sg"
    description = "Access through only Loadbalancer Securtiy group"
    vpc_id = "${aws_default_vpc.default.id}"

  
  #SSH

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
    
 
    }

  #HTTP

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.rehan_sg.id}"]
    }
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
   security_groups = ["${aws_security_group.rehan_sg.id}"]
    }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
    }



#internet gateway



# Route tables




resource "aws_lb" "rehan-lb" {
  name               = "rehan-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.rehan_sg.id}"]
  subnets            = ["subnet-6f610b41","subnet-7072c14e","subnet-73320d39"]
  enable_deletion_protection = false

  

  tags {
    Environment = "Rehannn"
  }
}
  resource "aws_lb_target_group" "main_no_logs" {
  name                 = "rehan-targetgroup"
  vpc_id               = "${aws_default_vpc.default.id}"
  port                 = "80"
  protocol             = "HTTP"
  deregistration_delay = "300"
  target_type          = "instance"
  slow_start = "60"
  
  
  health_check {
    interval            = "30"
    path                = "/"
    port                = "80"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    timeout             = "5"
    protocol            = "HTTP"
  }

  
  
  depends_on = ["aws_lb.rehan-lb"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = "${aws_lb.rehan-lb.arn}"
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    target_group_arn = "${aws_lb_target_group.main_no_logs.arn}"
    type             = "forward"
  }
}

/*****************************8*
to redirect following code will do , not doing it because will need domain and certificate for HTTPS
*******************************

resource "aws_lb_listener" "HTTPS" {
  load_balancer_arn = "${aws_lb.front_end.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
  }
}
  resource "aws_lb_listener" "redirection" {
  load_balancer_arn = "${aws_lb.front_end.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
*/

  resource "aws_launch_configuration" "rehan_lc" {
  name_prefix          = "wp_lc-"
  image_id             = "ami-02da3a138888ced85"
  instance_type        = "t2.micro"
  key_name = "${aws_key_pair.rehan1.id}"
  iam_instance_profile = "aws_demo"
  security_groups = ["${aws_security_group.rehan_lbonly-sg.id}"]

  user_data = "${file("user_data")}"
    
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "wp_asg" {
  name                      = "asg-${aws_launch_configuration.rehan_lc.id}"
  max_size                  = "5"
  min_size                  = "2"
  health_check_grace_period = "30"
  health_check_type         = "EC2"
  desired_capacity          = "2" 
  force_delete              = true
  target_group_arns         = ["${aws_lb_target_group.main_no_logs.id}"] 
 
  

  vpc_zone_identifier = ["subnet-6f610b41","subnet-7072c14e","subnet-73320d39"]

  launch_configuration = "${aws_launch_configuration.rehan_lc.name}"

  tag {
    key                 = "Name"
    value               = "rehan_asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

