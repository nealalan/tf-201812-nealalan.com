# tf-201812-nealalan.com
This repo contains two files:
- [vpc.tf](https://github.com/nealalan/tf-201812-nealalan.com/blob/master/vpc.tf) - a consolidated terraform file (infrastructure as code) to create a VPC, associated components and an EC2 Ubuntu instance in a Public Subnet
  - best practice is to seperate out the tf components into sections, but this worked out well for me to have it in one file
  - need to implement the logic to automatically push (scp?) the install.sh file to the EC2 instance and run it automatically
- [install.sh](https://github.com/nealalan/tf-201812-nealalan.com/blob/master/install.sh) - shell script to configure the Ubuntu instance to configure NGINX web server with secure websites (https)

## Result
My server is at static IP [18.223.13.99](http://18.223.13.99) serving [https://nealalan.com](https://nealalan.com) and [https://neonaluminum.com](https://neonaluminum.com) with redirects from all http:// addresses

