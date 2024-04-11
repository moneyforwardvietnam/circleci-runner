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
apt install nginx maven curl gnupg2 unzip python3-pip -y

# Install AWS CLI
apt install awscli -y

# Installing htmlq for ci tools
wget -qO htmlq.tar.gz https://github.com/mgdm/htmlq/releases/${HTMLQ_VERSION}/download/htmlq-x86_64-linux.tar.gz
tar xf htmlq.tar.gz -C /usr/local/bin
htmlq --version

echo "Installing CircleCI Runner for ${PLATFORM}"
if [ -z ${TOKEN} ]; then
  echo "ERROR: Please input your CircleCI Token"
  exit
fi

base_url="https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
if [ -z ${agent_version+x} ]; then
  agent_version=$(curl "${base_url}/release.txt")
fi

# Set up runner directory
echo "Setting up CircleCI Runner directory"
prefix=/var/opt/circleci
mkdir -p "${prefix}/workdir"
chmod 0750 ${prefix}/workdir

# Set up runner configuration
echo "Setting up CircleCI Runner config"
cat <<EOF > ${prefix}/launch-agent-config.yaml
api:
  auth_token: ${TOKEN}

runner:
  name: qa_automation_runner_${RANDOM_STRING}
  command_prefix: ["sudo", "-niHu", "root", "--"]
  ssh:
    advertise_addr: ${LOCAL_IP}:54782
  working_directory: ${prefix}/workdir
  cleanup_working_directory: true
EOF
chown root: ${prefix}/launch-agent-config.yaml
chmod 600 ${prefix}/launch-agent-config.yaml

# Downloading launch agent
echo "Using CircleCI Launch Agent version ${agent_version}"
echo "Downloading and verifying CircleCI Launch Agent Binary"
curl -sSL "${base_url}/${agent_version}/checksums.txt" -o checksums.txt
file="$(grep -F "${PLATFORM}" checksums.txt | cut -d ' ' -f 2 | sed 's/^.//')"
echo "Downloading CircleCI Launch Agent: ${file}"
mkdir -p "${PLATFORM}"
curl --compressed -L "${base_url}/${agent_version}/${file}" -o "${file}"

# Verifying download
systemctl stop circleci.service
echo "Verifying CircleCI Launch Agent download"
grep "${file}" checksums.txt | sha256sum --check && chmod +x "${file}"
cp -r "${file}" "${prefix}/circleci-launch-agent" || echo "Invalid checksum for CircleCI Launch Agent, please try download again"

# Setup circleci-agent as service
echo "Setup CircleCI Service"
cat <<EOF > /etc/systemd/system/circleci.service
[Unit]
Description=CircleCI Runner
After=network.target

[Service]
ExecStart=${prefix}/circleci-launch-agent --config ${prefix}/launch-agent-config.yaml
Restart=always
User=root
NotifyAccess=exec
TimeoutStopSec=18300

[Install]
WantedBy=multi-user.target
EOF

systemctl restart circleci.service


/tmp/install_selenium_server.sh
/tmp/install_google_chrome.sh
/tmp/install_chromedriver.sh
