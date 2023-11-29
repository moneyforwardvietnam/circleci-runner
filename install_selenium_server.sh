SELENIUM_VERSION="4.10.0"
SELENIUM_PARENT_VERSION="4.10.0"

# Download selenium binary
echo "Download Selenium Binary"
# curl --compressed -L https://github.com/SeleniumHQ/selenium/releases/download/selenium-${SELENIUM_VERSION}/selenium-server-${SELENIUM_VERSION}.jar -o /usr/local/bin/selenium-server.jar
curl --compressed -L https://github.com/SeleniumHQ/selenium/releases/download/selenium-${SELENIUM_PARENT_VERSION}/selenium-server-${SELENIUM_VERSION}.jar -o /usr/local/bin/selenium-server.jar

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
ExecStart=java -jar selenium-server.jar standalone --driver-implementation "chrome" --max-sessions 8 --override-max-sessions true --detect-drivers true --log /var/log/selenium.log
ExecStop=/bin/kill -15 $MAINPID

[Install]
WantedBy=multi-user.target
EOF

systemctl restart selenium.service
systemctl daemon-reload
