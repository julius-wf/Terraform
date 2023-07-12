provider "aws" {

    region = "eu-north-1"
}


resource "aws_instance" "MyUbuntru" {
    ami = "ami-0989fb15ce71ba39e"
    instance_type = "t3.micro"
    count = 0

    tags = {
      Name = "Ubuntu"
      Owner = "Dima"
      Project = "Lesson"
    }
  
}

resource "aws_instance" "MyAws" {
    ami = "ami-0617f77bd30aaddb7"
    instance_type = "t3.micro"
    count = 0

    tags = {
      Name = "AWS"
      Owner = "Dima"
      Project = "Lesson"
    }
}