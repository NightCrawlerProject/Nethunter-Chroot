#!/bin/bash
# Check for root
# script made by JakeFrostyYT
# https://gitlab.com/JakeFrostyYT
# This script is intended to be used to download packages into the folders in /repo
verbose=off
norecurse=off
arch=amd64
if [[ $EUID -ne 0 ]]; then
	echo "Please run this as root"
	exit 1
fi
display_help() {
	echo "Usage: ./recursivedownloader.sh [arguments]"
	echo
	echo "  -h, --help		  shows this screen, arguments are found here as well as how to use the script"
	echo "  -a, --arch		  specify what architecture to package will download (amd64 by default)"
}

exit_help() {
	display_help
	echo "Error: $1"
	exit 1
}
# This will check if no arguments are provided, if none will show display_help()
#if [ $# -eq 0 ]; then
#	display_help
#	exit 0
#fi

# process arguments
while [[ $# -gt 0 ]]; do
	arg=$1
	case $arg in
		-h|--help)
			display_help
			exit 0 ;;
		-a|--arch)
			case $2 in
				armhf|arm64|i386|amd64|all)
					arch=$2
					;;
				*)
					exit_help "Unknown architecture: $2"
					;;
			esac
			shift
			;;
		*)
			exit_help "Unknown argument: $arg"
			;;
	esac
	shift
done
read -rp "Packages Name: " pkg
echo "[+] Downloading $pkg and dependencies"
cd $arch && apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "$pkg:$arch" | grep "^\w" | sort -u)
