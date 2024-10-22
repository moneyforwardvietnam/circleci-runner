#!/usr/bin/env bash
# Use this script by passing circleci token as parameter : ./install_circleci_runner.sh YOUR_TOKEN
RANDOM_STRING=$(echo $RANDOM | md5sum | head -c 12)
PLATFORM="linux/amd64"
TOKEN=$1
INTERFACE=ens5
LOCAL_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
SELENIUM_VERSION="4.8.3"
HTMLQ_VERSION="latest"
AWS_CLI_VERSION="1.22.34"
#JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | awk '{print $3}')

echo "Install dependencies"
apt update -y
apt install nginx maven curl gnupg2 unzip python3-pip jq -y

# Install AWS CLI
apt install awscli -y

# Installing htmlq for ci tools
wget -qO htmlq.tar.gz https://github.com/mgdm/htmlq/releases/${HTMLQ_VERSION}/download/htmlq-x86_64-linux.tar.gz
tar xf htmlq.tar.gz -C /usr/local/bin
htmlq --version

echo "Installing CircleCI Runner for ${PLATFORM}"
# Check if RUNNER_AUTH_TOKEN is provided as an argument
if [ -z "$TOKEN" ]; then
  echo "Usage: $0 <RUNNER_AUTH_TOKEN>"
  exit 1
fi

# Install CircleCI runner
echo "Installing CircleCI runner..."
curl -s https://packagecloud.io/install/repositories/circleci/runner/script.deb.sh?any=true | sudo bash
sudo apt-get install -y circleci-runner

# Update the CircleCI runner configuration with the provided token
echo "Configuring CircleCI runner..."
sudo sed -i "s/<< AUTH_TOKEN >>/$TOKEN/g" /etc/circleci-runner/circleci-runner-config.yaml

# Enable and start the CircleCI runner service
echo "Starting CircleCI runner service..."
systemctl enable circleci-runner
systemctl start circleci-runner

echo "CircleCI runner installation and configuration completed."


/tmp/install_selenium_server.sh
/tmp/install_google_chrome.sh
/tmp/install_chromedriver.sh
