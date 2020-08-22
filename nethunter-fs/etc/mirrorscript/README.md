# mirrorScript
Script to change kali repository mirror

http://http.kali.org redirects you to the closest available mirror based on your physical location.
Most of the time the servers may experience heavy load, thus slowing down upgrades even with fast connection.
This script lets you rank(based on the server's ping) and choose an alternative mirror and override it.

The script works on a threaded model now, making ranking extremely quick.

You can find the original mirror list here [Kali Mirrors](https://http.kali.org/README.mirrorlist)

# Requirements
Kali Linux,
Python2.7 (comes pre-bundled)

# Usage
>Run the script in privilege mode, such that sources.list could be edited

> **$ sudo python mirrorscript.py**
