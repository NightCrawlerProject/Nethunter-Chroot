# Nethunter-Chroot
 ## i am not responsible for your actions! IN EVERY WAY ##
Your warranty is void. Or valid, probably?
I am not responsible for bricked devices, dead SD cards, etc
YOU are choosing to make these modificiations, and if
you point your finger at me for messing up your device, I will laugh at you or something.
Goodluck on testing.

## Requirements: ##
Nethunter app
Nethunter Terminal
Nethunter KeX Client
Atleast 8gb free space to ensure System stability
Root Access

Currently the chroot sits around 5.8Gb when uncompressed

###      How to install     ###
First:
You need to have installed nethunter rom, or any rom actually as long as you have the following installed

I will soon make a ROM with nethunter features out of the box

Second:
Install Magisk(Anything above magisk v20 is enough)

Third:
Download chroot from this repository
Put the downloaded chroot into your phone's internal storage
you can rename it to kalifs-arm64-full.tar.xz

Fourth:
Enter the nethunter app
In the nethunter app select Kali Chroot Manager,
click install, type the location of the chroot you downloaded (kali-arm64-full.tar.xz)


### Latest Changelog: ###

#### Changelog V2: ####
Major changes to the chroot

New Custom Commands:

listcustom - list all custom commands by JakeFrostyYT
Author: JakeFrostyYT

airgeddon - a multi-use bash script for Linux systems to audit wireless networks.
Author: v1s1t0r1sh3r3

chrootupdate - a script to update the chroot without the need to replace the current one entirely
Author: JakeFrostyYT

mirrorscript - Script to change kali repository mirror by jayantamadhav
Author: jayantamadhav

mirrorscript-v2 - Kali Mirrorscript-v2 by IceM4nn automatically select the best kali mirror server and apply the configuration
Author: IceM4nn

rcv - a custom script to automatically download a package together with its dependencies on the location specified
Author: JakeFrostYT

routersploit - Exploitation Framework for Embedded Devices
echo "${LIGHTGREEN}Author: threat9

Changes in sytem:

kali.download and old.kali.org now exist in
sources.list together instead of only old.kali.org

chroot will rely on chrootupdate command for changes in chroot to
avoid wasting alot of data by avoiding downloading a new chroot

chroot now has custom attributes and colors, see below for added attributes and colors

colors:
NOCOLOR, RED, GREEN, ORANGE, BLUE, PURPLE, CYAN, LIGHTGRAY, DARKGRAY, LIGHTRED, LIGHTGREEN, YELLOW, LIGHTBLUE, LIGHTPURPLE, LIGHTCYAN, WHITE
attributes:
BOLD, DIM, UNDERLINE, BLINK, REVERSE, HIDDEN, RESETALL, RESETBOLD, RESETDIM, RESETUNDERLINE, RESETBLINK, RESETREVERSE, RESETHIDDEN

usage examples
' echo -e "${RED}this is RED" '
' echo -e "no line ${UNDERLINE}underline${RESETUNDERLINE} no line" '
' echo -e "no blink ${BLINK}blink${RESETBLINK} no blink" '

Added Tools:
Airgeddon
chrootupdate
mirrorscript
mirrorscript-v2
rcv
routersploit
