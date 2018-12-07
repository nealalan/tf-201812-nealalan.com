#!/bin/sh
sudo apt -y update; sudo apt -y upgrade; sudo apt install -y nginx
sudo add-apt-repository ppa:certbot/certbot
sudo apt -y install python-certbot-nginx
sudo mkdir -p /var/www/nealalan.com/html
sudo mkdir -p /var/www/neonaluminum.com/html
