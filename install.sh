#!/bin/bash
set -e
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

apt install nodejs autoconf automake build-essential gcc g++ make rpm xvfb jq moreutils

sudo -u $real_user bash -c '\
	set -e

	if [ -d ./tuxedo-fan-control ]; then
		cd tuxedo-fan-control
		git reset --hard
		git pull
		cd ../
	else
		git clone https://github.com/tuxedocomputers/tuxedo-fan-control
	fi

	cp ./tuxedofancontrol.service ./tuxedo-fan-control/src/data
	cp ./fantables.json ./tuxedo-fan-control/src/data
	cp ./after_install.sh ./tuxedo-fan-control/scripts

	cd tuxedo-fan-control
	jq ".build.linux.target = [\"deb\"]" package.json | sponge package.json
	npm install && npm run build && npm run pack
'
cd tuxedo-fan-control
sudo dpkg -i output/build/*.deb
sudo systemctl status tuxedofancontrol.service
