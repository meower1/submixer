#!/bin/bash

sudo apt update -y
sudo apt install nginx python3 pip -y
sudo pip install -r dependencies/requirements.txt
clear


# Check if the SSL certificate is in place
read -p "Have you placed your SSL certificate and private key at /root/cert.crt and /root/private.key? (y/n): " ssl_cert_ready
read -p "Enter the domain name: " domain_name

if [ "$ssl_cert_ready" != "y" ]; then
  apt install curl socat -y
  curl https://get.acme.sh/ | sh
  ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
  ~/.acme.sh/acme.sh --register-account -m te324stus32er@gmail.com
  ~/.acme.sh/acme.sh --issue -d $domain_name --standalone
  ~/.acme.sh/acme.sh --installcert -d $domain_name --key-file /root/private.key --fullchain-file /root/cert.crt
  clear
  echo "Your ssl certificate is ready. the script will now continue"
  sleep 2

fi

# Get the server's IP address
server_ip=$(curl -s ifconfig.me)



# Replace variables in /etc/nginx/sites-available/default
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 443 ssl;


    ssl_certificate /root/cert.crt;
    ssl_certificate_key /root/private.key;

    server_name $domain_name;

 location / {

            proxy_pass http://$server_ip:5000;
            proxy_set_header X-Real-IP \$remote_addr;

        }
}

server {
    listen 80;

    server_name $domain_name;

    return 302 https://\$server_name\$request_uri;
}
EOF

# Start and enable nginx systemd service
systemctl start nginx
systemctl enable nginx

# Write the submixer service in /etc/systemd/system/submixer.service
cat <<EOF > /etc/systemd/system/submixer.service
[Unit]
Description= Submixer service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/bin/python3 /root/submixer/dependencies/main.py

[Install]
WantedBy=multi-user.target
EOF

# Write the flask service in /etc/systemd/system/flask.service
cat <<EOF > /etc/systemd/system/flask.service
[Unit]
Description= Submixer Flask service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/bin/python3 /root/submixer/Flask/app.py

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Start and enable submixer and flask systemd services
systemctl start submixer
systemctl enable submixer
systemctl start flask
systemctl enable flask
systemctl reload nginx

# Return the domain name in the https://domain.name format
echo "Your subscription is now accessible at https://$domain_name"
