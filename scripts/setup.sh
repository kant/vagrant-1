set -xe

ACCOUNT=$1
APPLICATION=$2
BRANCH=$3

export TEST=mysql

echo "Installing packages..."
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
sudo add-apt-repository -y ppa:ondrej/php

sudo apt-get -y update
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password temp_root_password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password temp_root_password'
sudo apt-get -y install openssh-server git vim wget curl tasksel php socat xvfb x11-utils default-jre zip php-zip php-curl php-mbstring mysql-server x11vnc php-mysql php-xml
sudo apt-get purge -y apache2
mysqladmin -u root -p'temp_root_password' password ''

echo "Installing modern Composer..."
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
rm composer-setup.php

echo "Installing NodeJS toolset..."
curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Installing source code..."
git clone -b ${BRANCH} --single-branch https://github.com/${ACCOUNT}/${APPLICATION} ${APPLICATION}
cd ${APPLICATION}
./tools/startSubmodulesTRAVIS.sh

echo "Preparing the server environment..."
./lib/pkp/tools/travis/prepare-webserver.sh
source ./lib/pkp/tools/travis/start-xvfb.sh
./lib/pkp/tools/travis/start-selenium.sh
x11vnc -display :99 &

echo "Building code dependencies..."
./lib/pkp/tools/travis/install-composer-dependencies.sh
npm install && npm run build

set +xe

echo "Preparing and running tests..."
source ./lib/pkp/tools/travis/prepare-tests.sh
lib/pkp/tools/travis/run-tests.sh
