# Mirrorscript-v2
Script to change official Kali repository to mirrors. This helps increase packages update and downloading for some user. Please visit my blog [post](https://www.metahackers.pro/speed-kali-linux-update/).

## Requirements
Kali Linux,
Python3

## Usage
Run the script in privilege mode, such that `sources.list` could be edited.

## Help
```
# python3 mirrorscript-v2.py -h
usage: mirrorscript-v2.py [-h] [-v] [-https] [-src]

Kali Mirrorscripts-v2 by IceM4nn automatically select the best kali mirror
server and apply the configuration

optional arguments:
  -h, --help     show this help message and exit
  -v, --verbose  enable verbose output
  -https         use HTTPS in apt transport (default HTTP)
  -src           enable sources packages (default disable)
```

## Sample output:
```
# python3 mirrorscript-v2.py -v -https -src

#
# Mirrorscripts-v2 - By Hazmirul Afiq
# Automatically select the best Kali mirror and apply the configuration
# https://github.com/IceM4nn/mirrorscript-v2
# https://www.metahackers.pro/speed-kali-linux-update/
#

[-] Checking if 'apt-transport-https' package is installed.
	- apt-transport-https is installed

[+] Getting mirror list ...
[+] Found a lists of mirrors:
	- https://hlzmel.fsmg.org.nz/kali
	- https://wlglam.fsmg.org.nz/kali
	- https://mirror.karneval.cz/pub/linux/kali
	- https://ftp.acc.umu.se/mirror/kali.org/kali
	- https://mirrors.dotsrc.org/kali
	- https://ftp.halifax.rwth-aachen.de/kali
	- https://ftp2.nluug.nl/os/Linux/distr/kali
	- https://ftp1.nluug.nl/os/Linux/distr/kali
	- https://mirror.neostrada.nl/kali
	- https://kali.download/kali
	- https://mirrors.ocf.berkeley.edu/kali

[+] Checking mirrors ... This could take some times.
[+] Finding the best latency
	- hlzmel.fsmg.org.nz             : 416.890
	- wlglam.fsmg.org.nz             : 388.998 
	- mirror.karneval.cz             : 391.414
	- ftp.acc.umu.se                 : 313.722
	- mirrors.dotsrc.org             : 314.235
	- ftp.halifax.rwth-aachen.de     : 291.252
	- ftp2.nluug.nl                  : 297.838
	- ftp1.nluug.nl                  : 302.336
	- mirror.neostrada.nl            : 294.256
	- kali.download                  : 40.478
	- mirrors.ocf.berkeley.edu       : 348.848

[+] Fastest mirror: ('kali.download', '040.478')
[+] Preparing ...
	- Making a backup file /etc/apt/sources.list.bk ...
	- Checking sources.list for older entries ...
	- Commenting older entries ...
	- Done

[+] Updating sources.list with new entry ...
	- Your new mirror: https://kali.download/kali

[+] Done!
	- Run 'apt clean; apt update' for the changes to load.

```