# [nealalan.github.io](https://nealalan.github.io)/[tf-201812-nealalan.com](https://nealalan.github.io/tf-201812-nealalan.com)

## Project Goal
- Fully automate the creation of an NGINX webserver running on AWS EC2.
- Stay security minded by restricting network access and creating a secure web server. Check yours passes the smell test at:  [Sophos Security Headers Scanner](https://securityheaders.com/) and [SSL Labs test
](https://www.ssllabs.com/ssltest).

## Prereqs
- See [https://nealalan.github.io/EC2_Ubuntu_LEMP/](https://nealalan.github.io/EC2_Ubuntu_LEMP/) project and go through the steps up until VPC, they include:
  - Review terminology and scope
  - About the AWS free tier
  - Identity & Access Management (IAM)
  - Registering your domain name and creating a Hosted Zone in Route 53
  - [VPC CIDR Address](https://github.com/nealalan/EC2_Ubuntu_LEMP/blob/master/README.md#vpc-cidr-address) and [Public Subnet](https://github.com/nealalan/EC2_Ubuntu_LEMP/blob/master/README.md#vpc-public-subnetwork-subnet)
  - [EC2: Network & Security: Key Pairs](https://github.com/nealalan/EC2_Ubuntu_LEMP/blob/master/README.md#ec2-network--security-key-pairs)
  - The first step in [Connect to your instance](https://github.com/nealalan/EC2_Ubuntu_LEMP/blob/master/README.md#connect-to-your-instance) - except here you can connect to ubuntu@domain.com or ubuntu@EIP
- An AWS account with the IAM keys created for use in terraform
- Install [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) or search your package manager
  - Configure terraform with IAM keys
- Optional:
  - Atom installed
  - Github installed
  
## Files
This repo contains two files:
- [vpc.tf](https://github.com/nealalan/tf-201812-nealalan.com/blob/master/vpc.tf) - a consolidated terraform file (infrastructure as code) to create a VPC, associated components and an EC2 Ubuntu instance in a Public Subnet
  - best practice is to separate out the terraform components into sections, but this worked out well for me to have it in one file
  - need to implement the logic to automatically push (scp?) the install.sh file to the EC2 instance and run it automatically
- [install.sh](https://github.com/nealalan/tf-201812-nealalan.com/blob/master/install.sh) - shell script to configure the Ubuntu instance to configure NGINX web server with secure websites (https)
  - website are automatically pulled from git repos for respective sites

## Steps / Commands
I used... 
1. git clone this repo
2. terraform init
3. terraform plan
4. terraform apply
5. ssh -i priv_key.pem ubuntu@ip
6. curl https://raw.githubusercontent.com/nealalan/tf-201812-nealalan.com/master/install.sh > install.sh
7. chmod +x ./install.sh
8. .install.sh

Optional:
- terraform plan -destroy
- terraform destroy


## Result
My server is at static IP [18.223.13.99](http://18.223.13.99) serving [https://nealalan.com](https://nealalan.com) and [https://neonaluminum.com](https://neonaluminum.com) with redirects from all http:// addresses

![](https://raw.githubusercontent.com/nealalan/EC2_Ubuntu_LEMP/master/sites-as-https.png)

## NEXT STEPS
As you move around you'll need to log in to the AWS Console and add your local IP address to the EC2: Network ACLs. Here's an example of one I had in the past...

![](https://raw.githubusercontent.com/nealalan/EC2_Ubuntu_LEMP/master/ACLsshlist.png)

[[edit](https://github.com/nealalan/tf-201812-nealalan.com/edit/master/README.md)]
