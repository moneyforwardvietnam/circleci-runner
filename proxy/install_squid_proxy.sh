#!/bin/bash

# Update system repositories
sudo apt-get update -y

# Install Squid and Apache utilities (for htpasswd)
sudo apt-get install -y squid apache2-utils

# Define your user and password
USERNAME=$1
PASSWORD=$2
PASSWORD_FILE="/etc/squid/passwords"

# Create a password file and add a user with the password
sudo touch $PASSWORD_FILE
sudo chown proxy:proxy $PASSWORD_FILE
sudo htpasswd -bB $PASSWORD_FILE $USERNAME $PASSWORD

# Backup the original Squid configuration file
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Configure Squid for anonymous browsing and basic authentication
cat << EOF | sudo tee /etc/squid/squid.conf
http_port 0.0.0.0:3128

# Basic authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth $PASSWORD_FILE
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
cache deny all
acl SSL_ports port 1-65535
acl Safe_ports port 1-65535

# Define ACL for no authentication required
acl no_auth_ips src 10.1.0.1 # MFV gateway for local test
acl no_auth_ips src 52.199.24.153 # qa-runner
acl no_auth_ips src 18.181.241.59 # qa-ubuntu

# Allow specific IP to access without authentication
http_access allow no_auth_ips

# Allow authenticated users
http_access allow authenticated

# Allow all headers
request_header_access Allow all

# Only allow cachemgr access from localhost
http_access allow localhost manager

http_access deny manager

# Deny all other access
http_access deny all
EOF

# Restart Squid to apply the changes
sudo systemctl restart squid

echo "Squid Proxy installation and configuration complete."
