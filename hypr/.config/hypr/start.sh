#!/usr/bin/env bash

# Wallpaper
swww init &
swww img ~/Images/blobs-d.png &

# Network indicator
nm-applet --indicator &

waybar &

# Clipboard
copyq --start-server & 
copyq config hide_main_window true

# Redshift
systemctl --user start redshift
