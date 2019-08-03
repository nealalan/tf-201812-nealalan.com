#!/bin/bash

###############################################################################
### Neal Dreher / nealalan.com / nealalan.github.io/tf-201812-nealalan.com
### Recreate nealalan.* & neonaluminum.* on Ubuntu (AWS EC2)
### 2018-12-06
###
### Something I like to do after install is edit the ~/.bashrc PS1= statment to include (\D{%F %T}) at the beginning
###
### UPDATES
### - added additional subdomains and node and pm2
###############################################################################

## check for remote package updated and refresh the local package reference
sudo apt -y update
sudo apt -y upgrade

# nginx might already be installed...
sudo apt install -y nginx

# overwrite the generic ip-###-##-##-### hostname
echo "nealalan.com" | sudo tee /etc/hostname

# add domain names as localhosts
sudo sed -i '1s/^/127.0.0.1 ozark.neonaluminum.com\n/' /etc/hosts
sudo sed -i '1s/^/127.0.0.1 fire.neonaluminum.com\n/' /etc/hosts
sudo sed -i '1s/^/127.0.0.1 www.neonaluminum.com\n/' /etc/hosts
sudo sed -i '1s/^/127.0.0.1 neonaluminum.com\n/' /etc/hosts
sudo sed -i '1s/^/127.0.0.1 www.nealalan.com\n/' /etc/hosts
sudo sed -i '1s/^/127.0.0.1 nealalan.com\n/' /etc/hosts

# certbot
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt -y update
sudo apt -y upgrade
sudo apt -y install python-certbot-nginx

# Configure NGINX webserver files
sudo mkdir -p /var/www/nealalan.com/html
sudo mkdir -p /var/www/neonaluminum.com/html
sudo mkdir -p /var/www/fire.neonaluminum.com
sudo mkdir -p /var/www/ozark.neonaluminum.com

ln -s /var/www/nealalan.com/html /home/ubuntu/nealalan.com
ln -s /var/www/neonaluminum.com/html /home/ubuntu/neonaluminum.com
ln -s /var/www/fire.neonaluminum.com /home/ubuntu/fire.neonaluminum.com
ln -s /var/www/ozark.neonaluminum.com /home/ubuntu/ozark.neonaluminum.com

sudo chown -R ubuntu:ubuntu /var/www/nealalan.com/html
sudo chown -R ubuntu:ubuntu /var/www/neonaluminum.com/html
sudo chown -R ubuntu:ubuntu /var/www/fire.neonaluminum.com
sudo chown -R ubuntu:ubuntu /var/www/ozark.neonaluminum.com

ln -s /etc/nginx/sites-available /home/ubuntu/sites-available
ln -s /etc/nginx/sites-enabled /home/ubuntu/sites-enabled

sudo tee -a /home/ubuntu/sites-available/nealalan.com << END
server {
	listen 80;
	server_name nealalan.com www.nealalan.com;
	if ($host = nealalan.com) {
		return 301 https://$host$request_uri;
  }
  if ($host = www.nealalan.com) {
		return 301 https://$host$request_uri;
  }
}
server {
	listen 443 ssl;
	server_name nealalan.com www.nealalan.com;

	#  HTTP Strict Transport Security (HSTS) within the 443 SSL server block.
	add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
	# Server_tokens off
	server_tokens off;
	# Disable content-type sniffing on some browsers
	add_header X-Content-Type-Options nosniff;
	# Set the X-Frame-Options header to same origin
	add_header X-Frame-Options SAMEORIGIN;
	# enable cross-site scripting filter built in, See: https://www.owasp.org/index.php/List_of_useful_HTTP_headers
	add_header X-XSS-Protection "1; mode=block";
	# disable sites with potentially harmful code, See: https://content-security-policy.com/
	add_header Content-Security-Policy "default-src 'self'; script-src 'self' ajax.googleapis.com; object-src 'self';";
	# referrer policy
	add_header Referrer-Policy "no-referrer-when-downgrade";
	# webappsec-feature-policy
	Feature-Policy: microphone 'none'; camera 'none'; notifications 'none'; push 'none'
	# certificate transparency, See: https://thecustomizewindows.com/2017/04/new-security-header-expect-ct-header-nginx-directive/
	add_header Expect-CT max-age=3600;
	# HTML folder
	root /var/www/nealalan.com/html;
	index index.html;
}
END

sudo tee -a /home/ubuntu/sites-available/neonaluminum.com << END
server {
	listen 80;
	server_name neonaluminum.com www.neonaluminum.com;
	if ($host = neonaluminum.com) {
			return 301 https://$host$request_uri;
	}
	if ($host = www.neonaluminum.com) {
		return 301 https://$host$request_uri;
	}
}
server {
	listen 443 ssl;
	server_name neonaluminum.com www.neonaluminum.com;

	#  HTTP Strict Transport Security (HSTS) within the 443 SSL server block.
	add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
	# Server_tokens off
	server_tokens off;
	# Disable content-type sniffing on some browsers
	add_header X-Content-Type-Options nosniff;
	# Set the X-Frame-Options header to same origin
	add_header X-Frame-Options SAMEORIGIN;
	# enable cross-site scripting filter built in, See: https://www.owasp.org/index.php/List_of_useful_HTTP_headers
	add_header X-XSS-Protection "1; mode=block";
	# disable sites with potentially harmful code, See: https://content-security-policy.com/
	add_header Content-Security-Policy "default-src 'self'; script-src 'self' ajax.googleapis.com; object-src 'self';";
	# referrer policy
	add_header Referrer-Policy "no-referrer-when-downgrade";
	# webappsec-feature-policy
	Feature-Policy: microphone 'none'; camera 'none'; notifications 'none'; push 'none'
	# certificate transparency, See: https://thecustomizewindows.com/2017/04/new-security-header-expect-ct-header-nginx-directive/
	add_header Expect-CT max-age=3600;
	# HTML folder
	root /var/www/neonaluminum.com/html;
	index index.html;
}
END

sudo tee -a /home/ubuntu/sites-available/fire.neonaluminum.com << END
server {
	listen 80;
	server_name fire.neonaluminum.com;
  if ($host = fire.neonaluminum.com) {
    return 301 https://$host$request_uri;
  }
}
server {
	listen 443 ssl;
  	server_name fire.neonaluminum.com;
	root /var/www/fire.neonaluminum.com;
	location / {
		# reverse proxy and serve the app
		proxy_pass http://localhost:8080/;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_set_header Host $host;
		proxy_set_header X-Forwarded-Proto $scheme;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}
END
sudo tee -a /home/ubuntu/sites-available/ozark.neonaluminum.com << END
server {
	listen 80;
	server_name ozark.neonaluminum.com;
  if ($host = ozark.neonaluminum.com) {
    return 301 https://$host$request_uri;
  }
}
server {
	listen 443 ssl;
  	server_name ozark.neonaluminum.com;
	root /var/www/ozark.neonaluminum.com;
	location / {
		# reverse proxy and serve the app
		proxy_pass http://localhost:8081/;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_set_header Host $host;
		proxy_set_header X-Forwarded-Proto $scheme;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}
END

sudo rm /home/ubuntu/sites-enabled/default

# CREATE LINKS FROM SITES-AVAILABLE TO SITES-ENABLED
echo "CREATING LINKS TO NGINX CONFIG FILES"
sudo ln -s /etc/nginx/sites-available/nealalan.com /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/neonaluminum.com /etc/nginx/sites-enabled/

# restart NGINX
echo "REBOOTING NGINX"
sudo systemctl restart nginx

# RUN CERTBOT for all domains
#   https://certbot.eff.org/docs/using.html#certbot-commands
#
# Note: if you missed some and need to run again you will need to run 'ps aux' to get
#       the nginx process and use 'sudo kill <pid>' on the nginx main process
#       Next, run the same command with --expand on the end
echo "RUN CERTBOT ON ALL DOMAINS"echo "sudo certbot --authenticator standalone --installer nginx -d nealalan.com -d www.nealalan.com -d neonaluminum.com -d www.neonaluminum.com -d fire.neonaluminum.com -d ozark.neonaluminum.com --pre-hook 'sudo service nginx stop' --post-hook 'sudo service nginx start' -m neal@nealalan.com --agree-tos --eff-email --redirect -q"
sudo certbot --authenticator standalone --installer nginx -d nealalan.com -d www.nealalan.com -d neonaluminum.com -d www.neonaluminum.com -d fire.neonaluminum.com -d ozark.neonaluminum.com --pre-hook 'sudo service nginx stop' --post-hook 'sudo service nginx start' -m neal@nealalan.com --agree-tos --eff-email --redirect -q
echo "REBOOTING NGINX"
sudo systemctl restart nginx

# Ensure the latest git api is installed
sudo apt install -y git

# pull the websites from github down to the webserver
echo "CLONING nealalan.com, neonaluminum.com"
git clone https://github.com/nealalan/nealalan.com.git /home/ubuntu/nealalan.com
git clone https://github.com/nealalan/neonaluminum.com.git /home/ubuntu/neonaluminum.com

# INSTALL NODEJS
# install nodejs LTS versions - apt will not do this!
##sudo apt -y install nodejs npm
echo "INSTALLING NODE v12"
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt install -y nodejs gcc g++ make build-essential
sudo apt autoremove -y

# create hello.js
echo "CREATING hello.js"
sudo tee -a /home/ubuntu/sites-available/fire.neonaluminum.com/hello.js << END
#!/usr/bin/env nodejs
var http = require('http');
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(8080, 'localhost');
console.log('Server running at http://localhost:8080/');
END

# install the latest version of PM2 to manage production nodejs apps
echo "INSTALLING PM2"
sudo npm install pm2@latest -g

# SETUP PM2
# - start PM2 & set it up to automatically start on system reboot
# - allow without sudo: $ pm2 status
# - list pm2 processes
#   ALSO: pm2 monit | info <id> | stop <id> | start <path>

pm2 start /home/ubuntu/sites-available/fire.neonaluminum.com/hello.js
pm2 startup systemd
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu -hp /home/ubuntu
pm2 save
sudo chown ubuntu:ubuntu /home/ubuntu/.pm2/rpc.sock /home/neal/.pm2/pub.sock
pm2 ls


# INSTALL OTHER UTILS
sudo apt install -y speedtest-cli

# OPTIONAL
#sudo reboot
