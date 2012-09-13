#!/bin/bash

case $1 in

suspend)
	echo "NM suspend"
	#dbus-send --system --print-reply --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager.sleep
	sudo dbus-send --system --print-reply --reply-timeout=600 --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager.Sleep boolean:true

;;

resume)
	echo "NM resume"
        #dbus-send --system --print-reply --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager.wake
	sudo dbus-send --system --print-reply --reply-timeout=600 --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager.Sleep boolean:false

;;

*)
	echo "Usage: $0 [suspend|resume]"
;;

esac
