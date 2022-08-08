#!/usr/bin/env bash
# Use this script by passing circleci token as parameter : ./install_circleci_runner.sh YOUR_TOKEN
RANDOM_STRING=$(echo $RANDOM | md5sum | head -c 12)
PLATFORM="linux/amd64"
TOKEN=$1
LOCAL_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
SELENIUM_VERSION="4.3.0"
#JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | awk '{print $3}')

echo "Install dependencies"
apt update && apt upgrade -y
apt install nginx maven curl gnupg2 unzip -y

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

# Download selenium binary
echo "Download Selenium Binary"
# curl --compressed -L https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar -o /usr/local/bin/selenium-server.jar
curl --compressed -L https://github.com/SeleniumHQ/selenium/releases/download/selenium-${SELENIUM_VERSION}/selenium-server-${SELENIUM_VERSION}.jar -o /usr/local/bin/selenium-server.jar

# Setup selenium server as service
echo "Setup Selenium Service"
cat <<EOF > /etc/systemd/system/selenium.service
[Unit]
Description=Selenium service
After=syslog.target network.target

[Service]
SuccessExitStatus=143
User=root
Group=root
Type=simple
WorkingDirectory=/usr/local/bin
ExecStart=java -jar selenium-server.jar standalone --log /var/log/selenium.log
ExecStop=/bin/kill -15 $MAINPID

[Install]
WantedBy=multi-user.target
EOF

systemctl restart selenium.service
systemctl daemon-reload

./install_google_chrome.sh
./install_chromedriver.sh
