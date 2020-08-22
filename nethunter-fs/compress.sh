#!/bin/bash
if [[ $EUID -ne 0 ]]; then
	echo "Please run this as root"
	exit 1
fi
display_help() {
	echo "Usage: ./compress.sh [folder] [output-file-name]"
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
folder=$1
output=$2
XZ_OPTS=-9 tar cJvf "${output}.tar.xz" "$folder/"
echo "[+] Generating sha512sum of kalifs."
sha512sum "${output}.tar.xz" | sed "s|output/||" > "${output}.sha512sum"
