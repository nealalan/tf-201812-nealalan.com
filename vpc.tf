### Neal Dreher / nealalan.com / nealalan.github.io/tf-201812-nealalan.com
### Recreate nealalan.* & neonaluminum.*
### 2018-12-05
###
###
### A good base: https://hackernoon.com/manage-aws-vpc-as-infrastructure-as-code-with-terraform-55f2bdb3de2a
###
###

# USE:
#  $ terraform init
#  $ terraform plan
#  $ terraform apply
#
#  Note: to ssh to the server i'll need to update the local known_hosts using:
#  $ ssh-keyscan -t ecdsa nealalan.com >> ~/.ssh/known_hosts

# Shared Credentials
#  located at ~/.aws/credentials the file will have the format:
#     [profile]
#     aws_access_key_id = "AKIA..."
#     aws_secret_access_key = "a+b=3/0..."

# Variables
variable "aws_region" {
  description = "Region for the VPC"
  # Note: us-east-2	= OHIO
  default = "us-east-2"
}

variable "creds_path" {
  description = "AWS API key credentials path"
  default = "~/.aws/credentials"
}

variable "creds_profile" {
  description = "Profile in the credentials file"
  default = "tf-nealalan"
}

# cidr_block
#   Private network range 10.0.0.1 = 10.255.255.255; 172.16.0.0 - 172.31.255.255; etc
variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  default = "172.17.0.0/16"
}

variable "vpc_tag_name" {
  default = "nealalan-com-201812"
}

variable "subnet_az_a" {
  default = "us-east-2a"
}

variable "public_subnet_cidr" {
  default = "172.17.1.0/24"
}

variable "private_subnet_cidr" {
  default = "172.17.2.0/24"
}

variable "pub_key_path" {
  default = "~/.ssh/neals_web_server_pub.pem"
}

variable "pub_key_name" {
  default = "neals_web_server"
}

variable "igw_tag_name" {
  default = "nealalan-com-201812-IGW"
}

variable "ami" {
  description = "Ubuntu Server 18.04 LTS"
  default = "ami-0f65671a86f061fcd"
}

variable "instance_az_a" {
  default = "us-east-2a"
}

variable "instance_assigned_elastic_ip" {
  default = "18.223.13.99"
}

# Configure the AWS Provider
#  credentials default location is $HOME/.aws/credentials
#
# Docs: https://www.terraform.io/docs/providers/aws/index.html

provider "aws" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.creds_path}"
  profile                 = "${var.creds_profile}"
  #access_key              = "${var.aws_access_key_id}"
  #secret_key              = "${var.aws_secret_access_key}"
}

# Create a Virtual Private Cloud
#   instance_tenancy
#     [default] = Your instance runs on shared hardware.
#     dedicated = Your instance runs on single-tenant hardware.
#     host = Your instance runs on a Dedicated Host, which is an isolated server with configurations that you can control.
#
# Docs: https://www.terraform.io/docs/providers/aws/d/vpc.html

resource "aws_vpc" "main" {
  cidr_block       = "${var.vpc_cidr}"
  enable_dns_hostnames = "True"
  #instance_tenancy = ""
  tags {
    Name = "${var.vpc_tag_name}"
    Author = "terraform"
  }
}

# Create Subnets
resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.public_subnet_cidr}"
  availability_zone = "${var.subnet_az_a}"
  tags {
    Name = "Public Subnet A"
    Author = "terraform"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.private_subnet_cidr}"
  availability_zone = "${var.subnet_az_a}"
  tags {
    Name = "Private Subnet A"
    Author = "terraform"
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.igw_tag_name}"
    Author = "terraform"
  }
}

# Create the route table
resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "Public Subnet RT"
    Author = "terraform"
  }
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "web-public-rt" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

# Define the security group for public subnet
#  enable HTTP/HTTPS, ping and SSH connections from anywhere
resource "aws_security_group" "sgpub" {
  name = "public_sg"
  description = "Allow incoming HTTP connections & SSH access"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  ingress {
    from_port = 32768
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id="${aws_vpc.main.id}"
  tags {
    Name = "Public Subnet SG"
    Author = "terraform"
  }
}

# Define the security group for private subnet
#   enable MySQL 3306, ping and SSH only from the public subnet
resource "aws_security_group" "sgpriv"{
  name = "private_sg"
  description = "Allow traffic from public subnet"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }
  ingress {
    from_port = 32768
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "Private Subnet SG"
    Author = "terraform"
  }
}

# Public key for access to EC2 instances
resource "aws_key_pair" "default" {
  key_name = "${var.pub_key_name}"
  public_key = "${file("${var.pub_key_path}")}"
}

# Create EC2 Instance
resource "aws_instance" "wb" {
   ami  = "${var.ami}"
   instance_type = "t2.micro"
   key_name = "${var.pub_key_name}"
   subnet_id = "${aws_subnet.public-subnet.id}"
   vpc_security_group_ids = ["${aws_security_group.sgpub.id}"]
   associate_public_ip_address = true
   #public_ip = "${var.instance_assigned_elastic_ip}"
   #source_dest_check = false
   availability_zone = "${var.instance_az_a}"
  tags {
    Name = "${var.vpc_tag_name}"
    Author = "terraform"
  }
}

# Assign Existing EIP
resource "aws_eip_association" "static_ip" {
  instance_id   = "${aws_instance.wb.id}"
  public_ip = "${var.instance_assigned_elastic_ip}"
}
