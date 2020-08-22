#!/bin/bash
# Check for root
# Script by JakeFrostyYT
# https://github.com/JakeFrostyYT/rcv.git
verbose=off
norecurse=off
arch=all
if [[ $EUID -ne 0 ]]; then
	echo "Please run this as root"
	exit 1
fi
display_help() {
	echo "Usage: rcv [package] [architecture] [output-directory] [list]"
	echo "example for downloading: rcv python amd64 python-folder"
	echo "example for listing deps: rcv python amd64 list"
}

exit_help() {
	display_help
	echo "Error: $1"
	exit 1
}
# This will check if no arguments are provided, if none will show display_help()
if [ $# -eq 0 ]; then
	display_help
	exit 0
fi

pkg=$1
arch=$2
dir=$3
# This will check if the 3rd argument is "list"
# If stated as list it will execute the list deps and proceed to download_stage()
list_check1() {
if [ "$dir" == "list" ]; then
	echo "$dir"
	pass_check
	
else
	echo "$dir"
	list_check2
fi
}

# Second check to see if list is specified in 4th variable
list_check2() {
if [ "$4" == "list" ]; then
	pass_check
else
	echo "[-] List mode not specified, Downloading dependencies recursively"
	directory_check
fi
}

pass_check() {
	echo "[+] List mode specified, Listing dependencies recursively"
	apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "${pkg}:${arch}" | grep "^\w" | sort -u
	exit 0
}

directory_check() {
if [ -z "$dir" ]; then
	echo "[-] Directory not provided."
	echo "[+] Use current directory instead? y/n"
	read ans
	if [ "$ans" == "y" ]; then
		echo "[+] Using Current directory..."
		dir=.
		download_stage
	else
		echo "Operation cancelled..."
		exit 0
	fi
else
	download_stage
fi
}

download_stage() {
if [ -d "$dir" ]; then
  cd $dir && apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "${pkg}:${arch}" | grep "^\w" | sort -u)
  echo "[+] Dependencies and package downloaded recursively, check folder ${dir} for downloaded files"
	echo "[+] Do you want to install the packages after downloading? y/n"
	read ins
	if [ "$ins" == "y" ]; then
		echo "Installing packages"
		pwd
		dpkg -i *.deb
		echo "Sucessfully installed packages"
	else
		exit 0
	fi
else
  echo "[-] Directory doesn't exist, Create directory?"
  read ans2
  if [ "$ans2" == "y" ]; then
	echo "[+] Creating directory named $dir"
	mkdir "$dir"
	cd $dir && apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "${pkg}:${arch}" | grep "^\w" | sort -u)
	echo "[+] Dependencies and package downloaded recursively, check folder ${dir} for downloaded files"
	echo "[+] Do you want to install the packages after downloading? y/n"
	read ins
	if [ "$ins" == "y" ]; then
		echo "Installing packages"
		pwd
		dpkg -i *.deb
		echo "Sucessfully installed packages"
	else
		exit 0
	fi
  else
	echo "Operation cancelled..."
	exit 0
  fi
fi
}

# Actual start of script
# process arguments
while [[ $# -gt 0 ]]; do
	arg=$1
	case $arg in
		-h|--help)
			display_help
			exit 0 ;;
	esac
	shift
done

list_check1
