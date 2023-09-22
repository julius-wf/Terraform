provider "aws" {
  region = "eu-north-1"
  profile = "default"
}

#VARIBLE


variable "env" {
  default = "main"
}




#VPC

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env}-vpc"
  }
}

#INTERNET_GATEWAY

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}

#PUBLIC_SUBNET

resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-north-1a"
  
  
  tags = {
    Name = "${var.env}-public"
  }
}

#ROUTING



resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.env}-route-public-subnets"
  }
}


#Assotiate

resource "aws_route_table_association" "public_routes" {
 
  route_table_id = aws_route_table.main.id
  subnet_id = aws_subnet.public_subnets.id
}

#aws_security_group

resource "aws_security_group" "main" {
  name        = "For K8s"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow ALL ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#SSH-KEY

resource "aws_key_pair" "master" {
    key_name = "master-node"
    public_key = file("~/.ssh/id_rsa.pub")
}

#EC2-instance

resource "aws_instance" "master" {
  subnet_id = aws_subnet.public_subnets.id
  ami = "ami-0989fb15ce71ba39e"
  instance_type = "t3.micro"
  key_name = aws_key_pair.master.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = "K8s-Master-node"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host = self.public_ip
  }

}

resource "aws_instance" "slave1" {
    subnet_id = aws_subnet.public_subnets.id
    ami = "ami-0989fb15ce71ba39e"
    instance_type = "t3.micro"
    key_name = aws_key_pair.master.key_name
    associate_public_ip_address = true

    vpc_security_group_ids = [aws_security_group.main.id]

    tags = {
      Name = "K8s-Slave1-node"
    }
}



#OUTPUT

output "public_ip" {
  value = aws_instance.master.public_ip
  
}