#!/bin/bash
gsettings set org.gnome.desktop.lockdown disable-lock-screen 'false'
gnome-screensaver-command -l
sleep 1s
gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
