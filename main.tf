terraform {
  required_providers {
    aws ={
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  reg1 = "us-east-1a"
  reg2 = "us-east-1b"
  ami = "ami-06b21ccaeff8cd686"
  type = "t2.micro"
  cidr1 = "10.0.1.0/24"
  cidr2 = "10.0.2.0/24"
  cidr3 = "10.0.3.0/24"
  cidr4 = "10.0.4.0/24"
  cidr5 = "10.0.5.0/24"
  cidr6 = "10.0.6.0/24"
}

variable "ami" {
  type = string
  default = "ami-06b21ccaeff8cd686"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

//VPC

resource "aws_vpc" "tier-3-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tier-3-vpc"
  }
}

//Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tier-3-vpc.id
}

//Route Table

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.tier-3-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

//Route Table Association

resource "aws_route_table_association" "rtb_association" {
  subnet_id = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "rtb_association1" {
  subnet_id = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.route_table.id
}

//Subnets in the VPC

resource "aws_subnet" "public-subnet-1" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = local.cidr1
  availability_zone = local.reg1
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = local.cidr2
  availability_zone = local.reg2
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = local.cidr3
  availability_zone = local.reg1

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = local.cidr4
  availability_zone = local.reg2

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = local.cidr5
  availability_zone = local.reg1

  tags = {
    Name = "private-subnet-3"
  }
}

resource "aws_subnet" "private-subnet-4" {
  vpc_id = aws_vpc.tier-3-vpc.id
  cidr_block = local.cidr6
  availability_zone = local.reg2

  tags = {
    Name = "private-subnet-4"
  }
}

//security group and security group rules
//front-end

resource "aws_security_group" "front-end-sg" {
  name = "front-end-sg"
  description = "allow all traffic from the internet"
  vpc_id = aws_vpc.tier-3-vpc.id

  tags = {
    Name = "front-end-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.front-end-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.front-end-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}

resource "aws_vpc_security_group_egress_rule" "fe-outbound-1" {
  security_group_id = aws_security_group.front-end-sg.id
  referenced_security_group_id = aws_security_group.logic-tier-sg.id
  from_port = 0
  ip_protocol = "icmp"
  to_port = 0
}

resource "aws_vpc_security_group_egress_rule" "fe-outbound-2" {
  security_group_id = aws_security_group.front-end-sg.id
  referenced_security_group_id = aws_security_group.logic-tier-sg.id
  from_port = 0
  ip_protocol = "tcp"
  to_port = 0
}

//logic-tier

resource "aws_security_group" "logic-tier-sg" {
  name = "logic-tier-sg"
  description = "allows traffic from front-end and to database tier"
  vpc_id = aws_vpc.tier-3-vpc.id

  tags = {
    Name = "logic-tier-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ping" {
  security_group_id = aws_security_group.logic-tier-sg.id
  referenced_security_group_id = aws_security_group.front-end-sg.id
  from_port = 0
  ip_protocol = "icmp"
  to_port = 0
}

resource "aws_vpc_security_group_egress_rule" "mysql" {
  security_group_id = aws_security_group.logic-tier-sg.id
  referenced_security_group_id = aws_security_group.db-tier-sg.id
  from_port = 3306
  ip_protocol = "tcp"
  to_port = 3306
}

//db-tier

resource "aws_security_group" "db-tier-sg" {
  name = "db-tier-sg"
  description = "allows traffic only from the logic tier"
  vpc_id = aws_vpc.tier-3-vpc.id

  tags = {
    Name = "db-tier-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds-inbound" {
  security_group_id = aws_security_group.db-tier-sg.id
  referenced_security_group_id = aws_security_group.logic-tier-sg.id
  from_port = 3306
  ip_protocol = "tcp"
  to_port = 3306
}

//EC2 and SG attachment

resource "aws_instance" "fe-1" {
  ami = var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  subnet_id = aws_subnet.public-subnet-1.id

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              sudo echo "Welcome to Ian's webserver." | sudo tee -a /var/www/html/index.html
              EOF
  
  tags = {
    Name = "fe-1"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe1" {
  security_group_id = aws_security_group.front-end-sg.id
  network_interface_id = aws_instance.fe-1.primary_network_interface_id
}

resource "aws_instance" "fe-2" {
  ami = var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  subnet_id = aws_subnet.public-subnet-2.id

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              sudo echo "Welcome to Ian's webserver." | sudo tee -a /var/www/html/index.html
              EOF

  tags = {
    Name = "fe-2"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe2" {
  security_group_id = aws_security_group.front-end-sg.id
  network_interface_id = aws_instance.fe-2.primary_network_interface_id
}

resource "aws_instance" "fe-3" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.private-subnet-3.id

  tags = {
    Name = "fe-3"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe3" {
  security_group_id = aws_security_group.logic-tier-sg.id
  network_interface_id = aws_instance.fe-3.primary_network_interface_id
}

resource "aws_instance" "fe-4" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.private-subnet-4.id

  tags = {
    Name = "fe-4"
  }
}

resource "aws_network_interface_sg_attachment" "sg_att_fe4" {
  security_group_id = aws_security_group.logic-tier-sg.id
  network_interface_id = aws_instance.fe-4.primary_network_interface_id
}

//RDS instance

resource "aws_db_subnet_group" "threetierdb-subnet-grp" {
  name = "threetierdb-subnet-grp"
  subnet_ids = [aws_subnet.private-subnet-3.id, aws_subnet.private-subnet-4.id]
}

resource "aws_db_instance" "threetierdb" {
  allocated_storage = 10
  db_name = "threetierdb"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  username = "username"  //replace
  password = "password1" //replace
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.threetierdb-subnet-grp.name
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.db-tier-sg.id]
  publicly_accessible = false
}