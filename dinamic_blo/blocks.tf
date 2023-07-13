provider "aws" {
  region = "eu-north-1"
}

resource "aws_default_vpc" "default" {} 

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