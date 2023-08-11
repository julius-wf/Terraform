provider "aws" {
  region = "eu-north-1"
}

data "aws_availability_zones" "available" {}


resource "aws_default_vpc" "default" {
  
}


resource "aws_default_subnet" "default_eu" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_eu1" {
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_instance" "high" {
  ami = "ami-0e70ee23034b6470c"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
}

#-------------------------------SEcurityGroup---------------------------------------

resource "aws_security_group" "web" {
  name        = "Dynamic-Blocks"
  vpc_id      = aws_default_vpc.default.id

    dynamic "ingress" {
        for_each = ["80", "443", "8080"]
        content {
          from_port = ingress.value
          to_port = ingress.value
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.10.0.0/16"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#------------------------------LAunchTemplate-------------------------------

resource "aws_launch_template" "web" {
  name = "web"
  image_id = aws_instance.high.ami
  instance_type = "t3.micro"
  security_group_names = [aws_security_group.web.id]
  user_data = filebase64("${path.module}/web.sh")
  tags = {
    Name = "My template"
  }
}


#-----------------------------AutoScalingGroup-------------------------

resource "aws_autoscaling_group" "web" {
  min_size = 1                                        
  max_size = 3
  min_elb_capacity = 1
  desired_capacity = 1
  health_check_type = "ELB"
  launch_configuration = aws_launch_template.web.id
  load_balancers = [aws_elb.web.name]
  vpc_zone_identifier = [aws_default_subnet.default_eu.id, aws_default_subnet.default_eu1.id]

  dynamic "tag" {
    for_each = {
      Name = "web"
      Owner = "Dima"
      TAGKEY = "TAGVALUE"

    }
  content {
    key = tag.key
    value = tag.value
    propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

#-------------------------------------LoadBalancer------------------------------

resource "aws_elb" "web" {
  name = "WebBalancer"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]  
  security_groups = [aws_security_group.web.id]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 10
  }
  tags = {
    name = "Webserser-ELB"
  }
}

