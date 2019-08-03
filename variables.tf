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
#  Change the project and author name as needed
#
#  $ terraform init
#  $ terraform plan
#  $ terraform apply
#
#  $ terraform plan -destroy
#  $ terraform destroy
#
#  Note: to ssh to the server i'll need to update the local known_hosts using:
#  $ ssh-keyscan -t ecdsa nealalan.com >> ~/.ssh/known_hosts
#  $ ssh-keyscan -t ecdsa neonaluminum.com >> ~/.ssh/known_hosts
#
# NOTES:
#  It seem the install.sh is too complex and requires user response to complete
#  Therefore, at this point it must be manually run with these steps:
#  $ curl https://raw.githubusercontent.com/nealalan/tf-201812-nealalan.com/
#     master/install.sh > install.sh
#  $ chmod +x ./install.sh
#  $ .install.sh
#
###############################################################################
# CHANGE 2019-05-23
#  Changed SSH access control from the Network ACL to a separate SG
#   to allow better visibility to access control at the instance level
#  Add ports 8080-8081
#
#  Future change:
#   - Add logic to curl down & chmod install.sh
#
# CHANGE 2019-07-03 
#   Setup the Cloudwatch Alarm to reboot an unreachable web server
#   Separated into individual files (not a monolith!!!)
###############################################################################
# Variables
###############################################################################
variable "project_name" {
  default = "nealalan-com-201812v2"
}
variable "author_name" {
  default = "terraform"
}
variable "acl_name" {
  default = "nealalan.com_acl"
}
### local machine variables!!!!
variable "pub_key_path" {
  ## generated from private key using 
  ## $ openssl rsa -in neals_web_server.pem -pubout > neals_web_server.pub
  ## WARNING: You must remove the "begin" and "end" lines from the file!!!
  description = "Pub key uploaded to EC2: Net & Sec: Key Pairs"
  default = "~/.aws/neals_web_server.pub"
}
variable "creds_path" {
  ## generated in IAM: Users: Security Creds
  ## stored in format:
  ## [tf-nealalan]
  ## aws_access_key_id = A...
  ## aws_secret_access_key = Z...
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
variable "instance_assigned_elastic_ip_cidr" {
  default = "18.223.13.99/32"
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
