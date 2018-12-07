# tf-201812-nealalan.com
This repo contains two files:
- consolidated terraform file (infrastructure as code) to create a VPC, associated components and an EC2 Ubuntu instance in a Public Subnet
- shell script to configure the Ubuntu instance to configure NGINX web server with secure websites (https)

## Result
My server is at static IP [18.223.13.99](18.223.13.99) serving [https://nealalan.com](https://nealalan.com) and [https://neonaluminum.com](https://neonaluminum.com) with redirects from all http:// addresses

