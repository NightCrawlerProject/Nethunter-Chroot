#!/bin/bash
#Execute first time install update and upgrade
if [[ "$EUID" -ne "0" ]]; then
	echo "Please run this as root"
	exit 1
fi
NOCOLOR='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
WHITE='\e[37m'
echo -e "${GREEN}[+] First Time Install Setup${NOCOLOR}"
sudo rm /etc/apt/sources.list
sudo touch /etc/apt/sources.list
chmod 755 /etc/apt/sources.list
cat << EOF >> "/etc/apt/sources.list"
deb http://kali.download/kali kali-rolling main contrib non-free
deb-src http://kali.download/kali kali-rolling main contrib non-free

# DO NOT REMOVE OLD.KALI.ORG
deb [trusted=yes] http://old.kali.org/kali 2019.1 main contrib non-free
deb-src [trusted=yes] http://old.kali.org/kali 2019.1 main contrib non-free
EOF

# Install via my script
packages="mitmf python3-pip"
sudo apt update -y
cd /etc/setup && sudo apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $packages | grep "^\w" | sort -u)
sudo dpkg -B -G --force-all -i /etc/setup/*.deb
sudo rm /etc/setup/*.deb
sudo apt update -y
sudo apt upgrade -y

#Install pip packages
pip="requests python-apt"
echo -e "${GREEN}Setup location:${WHITE}${setupenv}${NOCOLOR}"
echo -e "${GREEN}Proceeding...${NOCOLOR}"
pip3 install $pip
pip3 install -r $setupenv/requirements.txt
pip3 install -r /etc/routersploit/requirements.txt
pip3 install -r /etc/routersploit/requirements-dev.txt
rm /usr/share/mitmf/filepwn.py
python3 -m pip install bluepy

# Exec RSF setup
python3 /etc/routersploit/setup.py

sudo touch /etc/setup/.ftscheck
export NOCOLOR RED GREEN BLUE WHITE
echo -e "${GREEN}[+] Completed First Time Install Setup${NOCOLOR}"
