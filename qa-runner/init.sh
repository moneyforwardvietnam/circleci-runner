#!/bin/bash

## Global vars
##
GITHUB_IDS="tnqv shevchenki quangnhut123"
ENV_VAR="no_proxy=localhost,127.0.0.0/8"
ENV_FILE="/etc/environment"
user="ubuntu"

##
## Update package lists
##
sudo apt-get update -y
##
## Install dependencies
##
sudo apt-get install -y htop curl

## Set no_proxy to global /etc/environment
if grep -q "^no_proxy=" "$ENV_FILE"; then
    sudo sed -i "/^no_proxy=/c\\$ENV_VAR" "$ENV_FILE"
else
    echo "Adding no_proxy variable to $ENV_FILE."
    # Append the variable to the file
    echo "$ENV_VAR" | sudo tee -a "$ENV_FILE" > /dev/null
fi

##
## Fetching public keys from GitHub
##
for id in $GITHUB_IDS
do
    sudo curl -sS "https://github.com/$id.keys" >> /tmp/authorized_keys
done

echo "Disable Strict Host Key Checking"

tee -a /etc/ssh/ssh_config <<EOF
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF

##
## Setup SSH authorized_keys for user
##
echo "Setup SSH authorized_keys for $user user"
cp -rf /tmp/authorized_keys /home/$user/.ssh/authorized_keys
chown -R $user:$user /home/$user/.ssh
chmod 400 /home/$user/.ssh/authorized_keys
systemctl restart sshd.service

## Cleanup
##
if [ -f "/tmp/authorized_keys" ]; then
    echo "Cleanup authorized_keys"
    sudo rm -rf /tmp/authorized_keys
fi
