#!/bin/bash

INSTALL_DIR="/usr/local/bin"

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi
# determine_chrome_version
if uname -a | grep Darwin >/dev/null 2>&1; then
  echo "System detected as MacOS"
  CHROME_VERSION="$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version)"
  PLATFORM=mac64

elif grep Alpine /etc/issue >/dev/null 2>&1; then
  apk update >/dev/null 2>&1 &&
    apk add --no-cache chromium-chromedriver >/dev/null

  # verify version
  echo "$(chromedriver --version) has been installed to $(command -v chromedriver)"

  exit 0
else
  CHROME_VERSION="$(google-chrome --version)"
  PLATFORM=linux64
fi

CHROME_VERSION_STRING="$(echo "$CHROME_VERSION" | sed 's/.*Google Chrome //' | sed 's/.*Chromium //' | sed 's/[[:space:]]*$//')"

# print Chrome version
echo "Installed version of Google Chrome is $CHROME_VERSION_STRING"

# installation check
if command -v chromedriver >/dev/null 2>&1; then
  if chromedriver --version | grep "$CHROME_VERSION_STRING" >/dev/null 2>&1; then
    echo "ChromeDriver $CHROME_VERSION_STRING is already installed"
    exit 0
  else
    echo "A different version of ChromeDriver is installed ($(chromedriver --version)); removing it"
    $SUDO rm -f "$(command -v chromedriver)"
  fi
fi

echo "ChromeDriver $CHROME_VERSION_STRING will be installed"

# download chromedriver
curl --silent --show-error --location --fail --retry 3 \
  --output chromedriver_$PLATFORM.zip \
  "https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VERSION_STRING/$PLATFORM/chromedriver-$PLATFORM.zip"

# setup chromedriver installation
if command -v yum >/dev/null 2>&1; then
  yum install -y unzip >/dev/null 2>&1
fi

unzip "chromedriver_$PLATFORM.zip" >/dev/null 2>&1
rm -rf "chromedriver_$PLATFORM.zip"

CURRENT_DIR=$(pwd)

$SUDO mv $CURRENT_DIR/chromedriver-$PLATFORM/chromedriver "$INSTALL_DIR"
$SUDO chmod +x "$INSTALL_DIR/chromedriver"

# test/verify version
if chromedriver --version | grep "$CHROME_VERSION_STRING" >/dev/null 2>&1; then
  echo "$(chromedriver --version) has been installed to $(command -v chromedriver)"
else
  echo "Something went wrong; ChromeDriver could not be installed"
  exit 1
fi
