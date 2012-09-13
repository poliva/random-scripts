#!/bin/bash
# credentials are in /etc/davfs2/secrets
# instructions (from http://benjaminkerensa.com/2011/10/27/how-to-mount-box-net-securely-on-ubuntu-11-10 )
#
# sudo apt-get install davfs2
# sudo echo "https://www.box.net/dav username password" >> /etc/davfs2/secrets
# Access Box.net via Nautilus using WebDAV:
# Just use Connect to Server to dav://www.box.net/dav and make sure to select Secure WebDAV.

sudo mount -t davfs -o uid=pau -o gid=pau https://www.box.com/dav /media/box/
