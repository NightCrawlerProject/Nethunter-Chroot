#!/bin/bash
# DO NOT EXECUTE AFTER CHROOT IS COMPILED!
# Echo into .bashrc
if [ "$compiled" == "true" ]; then
	echo -e "${RED} execution of bashrc.sh is not allowed"
	echo -e "${RED} after chroot is compiled because"
	echo -e "${RED} because it duplicates .bashrc strings"
	echo -e "${RED} therefore is dangerous to execute twice"
	exit 1
fi
echo -e "${GREEN}[+] Adding strings into .bashrc${NOCOLOR}"
cat << EOF >> "/root/.bashrc"
alias cdb="cd ../"
buildver=$(cat "/root/version")
export buildver

# Disallow execution of bashrc.sh after chroot is compiled
compiled="true"
# Attributes
BOLD='\e[1m'
DIM='\e[2m'
UNDERLINE='\e[4m'
BLINK='\e[5m'
REVERSE='\e[7m'
HIDDEN='\e[8m'
RESETALL='\e[0m'
RESETBOLD='\e[21m'
RESETDIM='\e[22'
RESETUNDERLINE='\e[24m'
RESETBLINK='\e[25m'
RESETREVERSE='\e[27m'
RESETHIDDEN='\e[28m'

# Colors
NOCOLOR='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
ORANGE='\e[33m'
BLUE='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
LIGHTGRAY='\e[37m'
DARKGRAY='\e[30m'
LIGHTRED='\e[31m'
LIGHTGREEN='\e[92m'
YELLOW='\e[33m'
LIGHTBLUE='\e[34m'
LIGHTPURPLE='\e[35m'
LIGHTCYAN='\e[36m'
WHITE='\e[37m'

export NOCOLOR RED GREEN ORANGE BLUE PURPLE CYAN LIGHTGRAY DARKGRAY LIGHTRED LIGHTGREEN YELLOW LIGHTBLUE LIGHTPURPLE LIGHTCYAN WHITE
export BOLD DIM UNDERLINE BLINK REVERSE HIDDEN RESETALL RESETBOLD RESETDIM RESETUNDERLINE RESETBLINK RESETREVERSE RESETHIDDEN

if [ -f "/etc/setup/.ftscheck" ]; then
    /root/motd.sh
else
    echo -e "${RED}.ftscheck not found, please run setup."
fi
EOF
