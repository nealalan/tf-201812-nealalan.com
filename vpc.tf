###############################################################################
### Neal Dreher / nealalan.com / nealalan.github.io/tf-201812-nealalan.com
### Recreate nealalan.* & neonaluminum.*
### 2018-12-05
###
### A good help:
###   https://hackernoon.com/manage-aws-vpc-as-infrastructure-as-code-with-
###           terraform-55f2bdb3de2a
###   https://www.terraform.io/docs/providers/aws/
###
###############################################################################
# PRE-REQS:
#  1: local machine you're familar with using the command line on
#  2: terraform installed... search your package manager or see their site:
#     https://learn.hashicorp.com/terraform/getting-started/install.html
#  3: AWS account setup (this script will keep you within the free tier)
#  4: terraform configured with API keys (IAM user secret keys) from AWS
#     * see "Shared Credentials below"
#  5: github installed to clone this script
#  6: atom installed to edit this script
#
###############################################################################
# USE:
#  $ terraform init
#  $ terraform plan
#  $ terraform apply
#
#  $ terraform plan -destroy_grace_seconds
#  $ terraform destroy
#
#  Note: to ssh to the server i'll need to update the local known_hosts using:
#  $ ssh-keyscan -t ecdsa nealalan.com >> ~/.ssh/known_hosts
#  $ ssh-keyscan -t ecdsa neonaluminum.com >> ~/.ssh/known_hosts
#
# NOTES:
#  It seem the install.sh is too complex and requires user response to complete
#  Therefore, at this point it must be manually run with these steps:
#  $ curl https://raw.githubusercontent.com/nealalan/tf-201812-nealalan.com/master/install.sh > install.sh
#  $ chmod +x ./install.sh
#  $ .install.sh
#
###############################################################################
# Variables
###############################################################################
variable "project_name" {
  default = "nealalan-com-201812v2"
}
variable "author_name" {
  default = "terraform"
}
### local machine variables!!!!
variable "pub_key_path" {
  description = "Pub key uploaded to EC2: Net & Sec: Key Pairs"
  default = "~/.ssh/neals_web_server_pub.pem"
}
variable "creds_path" {
  description = "AWS API key credentials path"
  default = "~/.aws/credentials"
}
variable "creds_profile" {
  description = "Profile in the credentials file"
  default = "tf-nealalan"
}
### static for the cloud variables
variable "instance_assigned_elastic_ip" {
  default = "18.223.13.99"
}
variable "add_my_inbound_ip_cidr" {
  default = "73.95.223.217/32"
}
variable "aws_region" {
  # Note: us-east-2	= OHIO
  default = "us-east-2"
}
variable "az_a" {
  default = "us-east-2a"
}
# cidr_block
# Private network range 10.0.0.1-10.255.255.255; 172.16.0.0-172.31.255.255; etc
variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  default = "172.17.0.0/16"
}
variable "subnet_1_cidr" {
  default = "172.17.1.0/24"
}
variable "subnet_2_cidr" {
  default = "172.17.2.0/24"
}
variable "subnet_1_name" {
  default = "Public Subnet nealalan-com-201812v2"
}
variable "subnet_2_name" {
  default = "Private Subnet nealalan-com-201812v2"
}
variable "pub_key_name" {
  description = "Public key stored in EC2"
  default = "neals_web_server"
}
# ami is the "ID" of the OS installed on the instance
variable "ami" {
  description = "Ubuntu Server 18.04 LTS"
  default = "ami-0f65671a86f061fcd"
}

###############################################################################
# S T E P   0 1   :   Configure the AWS Provider
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
# S T E P   1 0   :   Create a Virtual Private Cloud
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
  enable_dns_hostnames = "True"
  #instance_tenancy = ""
  tags {
    Name = "${var.project_name}"
    Author = "${var.author_name}"
  }
}

###############################################################################
# S T E P   2 0   :   Create Subnets
#
# Public Subnet: to be used for a bastion host or public website
# Private Subnet: not currently used for this project but it's free
###############################################################################
resource "aws_subnet" "subnet-1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.subnet_1_cidr}"
  availability_zone = "${var.az_a}"
  tags {
    Name = "${var.subnet_1_name}"
    Author = "${var.author_name}"
  }
}
resource "aws_subnet" "private-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.subnet_2_cidr}"
  availability_zone = "${var.az_a}"
  tags {
    Name = "${var.subnet_2_name}"
    Author = "${var.author_name}"
  }
}

###############################################################################
# S T E P   3 0   :   Create the internet gateway
###############################################################################
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.project_name}"
    Author = "${var.author_name}"
  }
}

###############################################################################
# S T E P   3 3   :   Create the route table
###############################################################################
resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "Public Subnet RT"
    Author = "${var.author_name}"
  }
}

###############################################################################
# S T E P   3 6   :   Assign the route table to the public Subnet
###############################################################################
resource "aws_route_table_association" "web-public-rt" {
  subnet_id = "${aws_subnet.subnet-1.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

###############################################################################
# S T E P   4 0   :  Create an ACL for the EC2 instance
#
#  known usedful IPs: 18.223.13.99
###############################################################################
resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.main.default_network_acl_id}"
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "18.223.13.99/32"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = -1
    rule_no    = 101
    action     = "allow"
    cidr_block = "${var.add_my_inbound_ip_cidr}"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = 6
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = 6
    rule_no    = 301
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  ingress {
    protocol   = 6
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 32768
    to_port    = 65535
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags {
    Name = "nealalan.com_acl"
    Author = "${var.author_name}"
  }
}

###############################################################################
# S T E P   4 3   :  Define the security group for public subnet
#  enable HTTP/HTTPS, ping and SSH connections from anywhere
#
# INBOUND:
#  Allow from all IP addresses, internal & external
#  Open port 80 for http requests that will be redirected to https
#  Open port 443 for https redirect_all_requests_to
#  Open ICMP traffic
#   https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol
#  Open SSH traffic (filtered down by ACL)
#  Open TCP ports 32769-65535 https://en.wikipedia.org/wiki/Ephemeral_port
# OUTBOUND:
#  Allow all outbound traffic
###############################################################################
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
    Author = "${var.author_name}"
  }
}

###############################################################################
# S T E P   4 6   :  Define the security group for private subnet
#
# Instances in a Private subnet are pretty much impossible to create in the
#  AWS free tier.
# A method to cheat is to allow ephemeral ports access from the internet and
#  allow all outbound access to the open internet. This is no longer truly
#  private - but no one can initiate a connection to the instance without
#  going through an instance in the private subnet. (Treat the public web
#  server as a bastion host.)
#
# One option is to use a NAT gateway to allow internet access to instances
#  in private subnets. THERE IS A COST ASSOCIATED TO BOTH NAT OPTIONS!
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html
# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
#
# INBOUND:
#  Allow only traffic from the Internet Public Subnet CIDR
#   enable MySQL 3306, ping and SSH only from the public subnet
###############################################################################
resource "aws_security_group" "sgpriv"{
  name = "private_sg"
  description = "Allow traffic from public subnet"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["${var.subnet_1_cidr}"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["${var.subnet_1_cidr}"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.subnet_1_cidr}"]
    # something like this also may work???
    #cidr_blocks = ["${var.instance_assigned_elastic_ip},"/32""]
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
    Author = "${var.author_name}"
  }
}

###############################################################################
# S T E P   5 0   :  Upload Public key for access to EC2 instances
###############################################################################
resource "aws_key_pair" "default" {
  key_name = "${var.pub_key_name}"
  public_key = "${file("${var.pub_key_path}")}"
}

###############################################################################
# S T E P   6 0   :  Create EC2 Instance
#
# Execute install.sh for Ubuntu to configure
#   NGINX, CERTBOT
#   Pull git repos with websites
#
###############################################################################
resource "aws_instance" "wb" {
    ami  = "${var.ami}"
    instance_type = "t2.micro"
    key_name = "${var.pub_key_name}"
    subnet_id = "${aws_subnet.subnet-1.id}"
    vpc_security_group_ids = ["${aws_security_group.sgpub.id}"]
    associate_public_ip_address = true
    availability_zone = "${var.az_a}"
    tags {
      Name = "${var.project_name}"
      Author = "${var.author_name}"
    }
#    provisioner "file" {
#        source      = "install.sh"
#        destination = "/tmp/install.sh"
#    }
#    provisioner "remote-exec" {
#        inline = [
#          "chmod +x /tmp/install.sh",
#          "/tmp/install.sh",
#        ]
#    }
}

###############################################################################
# S T E P   6 3   :  Assign Existing EIP
#
# NOTE: I have an EIP already and assign it in the variables. If it sits
#  without being assigned to an instance or nat gateway, it will occur hourly
#  charges!!!!!
################################################################################
resource "aws_eip_association" "static_ip" {
  instance_id   = "${aws_instance.wb.id}"
  public_ip = "${var.instance_assigned_elastic_ip}"
}
