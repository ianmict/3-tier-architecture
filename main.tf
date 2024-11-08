terraform {
  required_providers {
    aws ={
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  reg1 = "us-east-1a"
  reg2 = "us-east-1b"
  ami = "ami-06b21ccaeff8cd686"
  type = "t2.micro"
}

variable "cidr_blocks_1" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "cidr_blocks_2" {
  type = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "cidr_blocks_3" {
  type = list(string)
  default = ["10.0.5.0/24", "10.0.6.0/24"]
}

provider "aws" {
  region = "us-east-1"
}

//VPC

resource "aws_vpc" "tier-3-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tier-3-vpc"
  }
}

//Subnets in the VPC

resource "aws_subnet" "public-subnet-1" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = local.reg1

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = local.reg2

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = local.reg1

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = local.reg2

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = local.reg1

  tags = {
    Name = "private-subnet-3"
  }
}

resource "aws_subnet" "private-subnet-4" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.6.0/24"
  availability_zone = local.reg2

  tags = {
    Name = "private-subnet-4"
  }
}

//security group

resource "aws_security_group" "front-end-sg" {
  name = "front-end-sg"
  description = "allow all traffic from the internet"
  vpc_id = aws_vpc.tier-3-vpc.id

  tags = {
    Name = "front-end-sg"
  }
}

resource "aws_security_group" "logic-tier-sg" {
  name = "logic-tier-sg"
  description = "allows traffic from front-end and to database tier"
  vpc_id = aws_vpc.tier-3-vpc.id

  tags = {
    Name = "logic-tier-sg"
  }
}

resource "aws_security_group" "db-tier-sg" {
  name = "db-tier-sg"
  description = "allows traffic only from the logic tier"
  vpc_id = aws_vpc.tier-3-vpc.id

  tags = {
    Name = "db-tier-sg"
  }
}

//security group rules

resource "aws_vpc_security_group_ingress_rule" "front-end-ingress" {
  security_group_id = aws_security_group.front-end-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
  from_port = 80
  to_port = 80

  tags = {
    Name = "front-end-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "front-end-egress" {
  for_each = toset(var.cidr_blocks_2)
  security_group_id = aws_security_group.front-end-sg.id
  cidr_ipv4 = each.value
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80

  tags = {
    Name = "front-end-egress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "logic-tier-ingress" {
  for_each = toset(var.cidr_blocks_1)
  security_group_id = aws_security_group.logic-tier-sg.id
  cidr_ipv4 = each.value
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80

  tags = {
    Name = "logic-tier-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "logic-tier-egress" {
  for_each = toset(var.cidr_blocks_3)
  security_group_id = aws_security_group.logic-tier-sg.id
  cidr_ipv4 = each.value
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306

  tags = {
    Name = "logic-tier-egress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db-tier-ingress" {
  for_each = toset(var.cidr_blocks_2)
  security_group_id = aws_security_group.db-tier-sg.id
  cidr_ipv4 = each.value
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306

  tags = {
    Name = "db-tier-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "db-tier-egress" {
  for_each = toset(var.cidr_blocks_2)
  security_group_id = aws_security_group.db-tier-sg.id
  cidr_ipv4 = each.value
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306

  tags = {
    Name = "db-tier-ingress"
  }
}

//EC2 and SG attachment

resource "aws_instance" "fe-1" {
  ami = local.ami
  instance_type = local.type

  tags = {
    Name = "fe-1"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe1" {
  security_group_id = aws_security_group.front-end-sg.id
  network_interface_id = aws_instance.fe-1.primary_network_interface_id
}

resource "aws_instance" "fe-2" {
  ami = local.ami
  instance_type = local.type

  tags = {
    Name = "fe-2"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe2" {
  security_group_id = aws_security_group.front-end-sg.id
  network_interface_id = aws_instance.fe-2.primary_network_interface_id
}

resource "aws_instance" "fe-3" {
  ami = local.ami
  instance_type = local.type

  tags = {
    Name = "fe-3"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe3" {
  security_group_id = aws_security_group.logic-tier-sg.id
  network_interface_id = aws_instance.fe-3.primary_network_interface_id
}

resource "aws_instance" "fe-4" {
  ami = local.ami
  instance_type = local.type

  tags = {
    Name = "fe-4"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe4" {
  security_group_id = aws_security_group.logic-tier-sg.id
  network_interface_id = aws_instance.fe-4.primary_network_interface_id
}