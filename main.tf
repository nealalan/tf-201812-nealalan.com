###############################################################################
# 01 : Configure the AWS Provider
#
# credentials default location is $HOME/.aws/credentials
# Docs: https://www.terraform.io/docs/providers/aws/index.html
#
###############################################################################
# Shared Credentials
#  located at ~/.aws/credentials the file will have the format:
#     [profile]
#     aws_access_key_id = "AKIA..."
#     aws_secret_access_key = "a+b=3/0..."
#
################################################################################
provider "aws" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.creds_path}"
  profile                 = "${var.creds_profile}"
  #access_key              = "${var.aws_access_key_id}"
  #secret_key              = "${var.aws_secret_access_key}"
}

###############################################################################
# 02 : Create a Virtual Private Cloud
#
#   instance_tenancy
#     [default] = Your instance runs on shared hardware.
#     dedicated = Your instance runs on single-tenant hardware.
#     host = Your instance runs on a Dedicated Host, which is an isolated server
#            with configurations that you can control.
# Docs: https://www.terraform.io/docs/providers/aws/d/vpc.html
###############################################################################
resource "aws_vpc" "main" {
  cidr_block       = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  #instance_tenancy = ""
  tags = {
    Name = "${var.project_name}"
    Author = "${var.author_name}"
  }
}

###############################################################################
# 03 : Create Subnets
#
# Public Subnet: to be used for a bastion host or public website
# Private Subnet: not currently used for this project but it's free
###############################################################################
resource "aws_subnet" "subnet-1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.subnet_1_cidr}"
  availability_zone = "${var.az_a}"
  tags = {
    Name = "${var.subnet_1_name}"
    Author = "${var.author_name}"
  }
}
resource "aws_subnet" "private-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.subnet_2_cidr}"
  availability_zone = "${var.az_a}"
  tags = {
    Name = "${var.subnet_2_name}"
    Author = "${var.author_name}"
  }
}

###############################################################################
# 04 : Create the internet gateway
###############################################################################
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "${var.project_name}"
    Author = "${var.author_name}"
  }
}

###############################################################################
# 05 : Create the route table
###############################################################################
resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "Public Subnet RT"
    Author = "${var.author_name}"
  }
}

###############################################################################
# 06 : Assign the route table to the public Subnet
###############################################################################
resource "aws_route_table_association" "web-public-rt" {
  subnet_id = "${aws_subnet.subnet-1.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}
