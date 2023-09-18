#!/bin/bash

sudo apt install nginx python3 pip -y
sudo pip install -r requirements.txt

# Step 0: Check if the SSL certificate is in place
read -p "Have you placed your SSL certificate and private key at /root/cert.crt and /root/private.key? (y/n): " ssl_cert_ready

if [ "$ssl_cert_ready" != "y" ]; then
  echo "Please place your SSL certificate and private key in /root/cert.crt and /root/private.key before running this script."
  exit 1
fi

# Step 1: Take the domain name from the user
read -p "Enter the domain name: " domain_name

# Step 2: Get the server's IP address
server_ip=$(curl -s ifconfig.me)



# Step 3: Replace variables in /etc/nginx/sites-available/default
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

# Step 4: Start and enable nginx systemd service
systemctl start nginx
systemctl enable nginx

# Step 5: Write the submixer service in /etc/systemd/system/submixer.service
cat <<EOF > /etc/systemd/system/submixer.service
[Unit]
Description= Submixer service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/bin/python3 /root/submixer/main.py

[Install]
WantedBy=multi-user.target
EOF

# Step 6: Write the flask service in /etc/systemd/system/flask.service
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

# Step 7: Start and enable submixer and flask systemd services
systemctl start submixer
systemctl enable submixer
systemctl start flask
systemctl enable flask
systemctl reload nginx

# Step 8: Return the domain name in the https://domain.name format
echo "Your website is now accessible at https://$domain_name"
