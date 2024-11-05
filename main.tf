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
}

provider "aws" {
  region = "us-east-1"
}

//VPC

resource "aws_vpc" "3-tier-VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "3-tier-VPC"
  }
}

//Subnets in the VPC

resource "aws_subnet" "public-subnet-1" {
  vpc_id = aws_vpc.3-tier-VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = local.reg1

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id = aws_vpc.3-tier-VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = local.reg2

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id = aws_vpc.3-tier-VPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = local.reg1

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = aws_vpc.3-tier-VPC.id
  cidr_block = "10.0.4.0/24"
  availability_zone = local.reg2

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  vpc_id = aws_vpc.3-tier-VPC.id
  cidr_block = "10.0.5.0/24"
  availability_zone = local.reg1

  tags = {
    Name = "private-subnet-3"
  }
}

resource "aws_subnet" "private-subnet-4" {
  vpc_id = aws_vpc.3-tier-VPC.id
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
  vpc_id = aws_vpc.3-tier-VPC.id

  tags = {
    Name = "front-end-sg"
  }
}

resource "aws_security_group" "logic-tier-sg" {
  name = "logic-tier-sg"
  description = "allows traffic from front-end and to database tier"
  vpc_id = aws_vpc.3-tier-VPC.id

  tags = {
    Name = "logic-tier-sg"
  }
}

resource "aws_security_group" "db-tier-sg" {
  name = "db-tier-sg"
  description = "allows traffic only from the logic tier"
  vpc_id = aws_vpc.3-tier-VPC.id

  tags = {
    Name = "db-tier-sg"
  }
}

//security group rules

resource "aws_security_group_ingress_rule" "front-end-ingress" {
  security_group_id = aws_security_group.front-end-sg.id
  cidr_block = "0.0.0.0/0"
  ip_protocol = "-1"
  from_port = 80
  to_port = 80

  tags = {
    Name = "front-end-ingress"
  }
}

resource "aws_security_group_egress_rule" "front-end-egress" {
  security_group_id = aws_security_group.front-end-sg.id
  cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"]
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80

  tags = {
    Name = "front-end-egress"
  }
}

resource "aws_security_group_ingress_rule" "logic-tier-ingress" {
  security_group_id = aws_security_group.logic-tier-sg.id
  cidr_block = ["10.0.1.0/24", "10.0.2.0/24"]
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80

  tags = {
    Name = "logic-tier-ingress"
  }
}

resource "aws_security_group_egress_rule" "logic-tier-egress" {
  security_group_id = aws_security_group.logic-tier-sg.id
  cidr_block = ["10.0.5.0/24", "10.0.6.0/24"]
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306

  tags = {
    Name = "logic-tier-egress"
  }
}

resource "aws_security_group_ingress_rule" "db-tier-ingress" {
  security_group_id = aws_security_group.db-tier-sg.id
  cidr_block = ["10.0.3.0/24", "10.0.4.0/24"]
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306

  tags = {
    Name = "db-tier-ingress"
  }
}

resource "aws_security_group_egress_rule" "db-tier-egress" {
  security_group_id = aws_security_group.db-tier-sg.id
  cidr_block = ["10.0.3.0/24", "10.0.4.0/24"]
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306

  tags = {
    Name = "db-tier-ingress"
  }
}

//EC2

resource "aws_instance" "fe-1" {
  ami = 
}