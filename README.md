# QA Runner Installation Script

This repository contains a script for installing and setting up a CircleCI runner with additional tools for QA automation tasks.

## Prerequisites

Before running the installation script, ensure that you have the following prerequisites:

- A CircleCI account and a personal API token.
- A machine running Ubuntu 22.04 with internet access.
- `sudo` privileges on the machine where the runner will be installed.

## Installation

To install the QA runner, follow these steps:

1. Clone the repository to your local machine or download the `install_circleci_runner.sh` script directly.

   curl -s https://${GITHUB_TOKEN}@raw.githubusercontent.com/moneyforwardvietnam/circleci-runner/master/install_circleci_runner.sh -o ~/install_squid_proxy.sh

3. Make the script executable:

   
   chmod +x install_circleci_runner.sh
   

4. Run the script with your CircleCI token as a parameter:

   
   ./install_circleci_runner.sh YOUR_CIRCLECI_TOKEN
   

   Replace `YOUR_CIRCLECI_TOKEN` with your actual CircleCI personal API token.

## What the Script Does

The installation script performs the following actions:

- Installs necessary dependencies including Nginx, Maven, Curl, GNUPG2, Unzip, Python3-pip, and a specific version of AWS CLI.
- Installs `htmlq` for CI tools.
- Sets up and installs the CircleCI runner for the `linux/amd64` platform.
- Configures the CircleCI runner with a unique name and SSH settings.
- Downloads and verifies the CircleCI Launch Agent binary.
- Sets up the CircleCI Launch Agent as a systemd service and starts it.
- Installs Selenium Server, Google Chrome, and ChromeDriver using additional scripts.

## Additional Scripts

The main installation script calls the following additional scripts:

- `install_selenium_server.sh`: Installs the Selenium Server.
- `install_google_chrome.sh`: Installs the Google Chrome browser.
- `install_chromedriver.sh`: Installs ChromeDriver for Selenium.

Ensure that these scripts are present in the same directory as the `install_circleci_runner.sh` script and are executable.

## Post-Installation

After the installation is complete, the CircleCI runner should be up and running. You can check the status of the runner service with:

systemctl status circleci.service

If you encounter any issues during installation, review the output logs and ensure that all prerequisites are met.

## Contributing

If you would like to contribute to the script or suggest improvements, please open an issue or submit a pull request to the repository.

