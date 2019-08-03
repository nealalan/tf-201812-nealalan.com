
###############################################################################
# 08 : Define the security group for public subnet & SSH access
#  enable HTTP/HTTPS, ping and SSH connections from anywhere
#
# INBOUND:
#  Allow from all IP addresses, internal & external
#  Open port 80 for http requests that will be redirected to https
#  Open port 443 for https redirect_all_requests_to
#  Open ICMP traffic
#   https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol
#  DO NOT Open SSH traffic (not filtered down by ACL)
#  Open TCP ports 32769-60999 https://en.wikipedia.org/wiki/Ephemeral_port
#    ports are set in instance at /proc/sys/net/ipv4/ip_local_port_range
# OUTBOUND:
#  Allow all outbound traffic
###############################################################################
resource "aws_security_group" "sgpub" {
  name = "public_sg"
  description = "Allow incoming HTTP connections"
  vpc_id = "${aws_vpc.main.id}"
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
    from_port = 8080
    to_port = 8081
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# SEPARATE SG FOR SSH ACCESS
#  ingress {
#    from_port = 22
#    to_port = 22
#    protocol = "tcp"
#    cidr_blocks =  ["0.0.0.0/0"]
#  }
  ingress {
    from_port = 32768
    to_port = 60999
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Public Subnet SG"
    Author = "${var.author_name}"
  }
}
resource "aws_security_group" "sgpubssh" {
  name = "public_sg_SSH"
  description = "Allow incoming SSH connections"
  vpc_id="${aws_vpc.main.id}"
}

###############################################################################
# 10 : Define the security group for private subnet
#
# Instances in a Private subnet are pretty much impossible to create in the
#  AWS free tier.
# A method to cheat is to allow ephemeral ports access from the internet and
#  allow all outbound access to the open internet. This is no longer truly
#  private - but no one can initiate a connection to the instance without
#  going through an instance in the public subnet. (Treat the public web
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
  tags = {
    Name = "Private Subnet SG"
    Author = "${var.author_name}"
  }
}
