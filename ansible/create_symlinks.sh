#!/bin/bash

users=('tuliopaim' 'p1' 'p2')

directories=(
    '.config',
    '.config/Code',
    '.config/Code/User',
    '.config/nvim',
    '.config/alacritty',
    '.tmux')

# Create the directories and symbolic links
for user in "${users[@]}"; do
   for directory in "${directories[@]}"; do
       sudo mkdir -p /home/$user/$directory
       sudo chown -R "${user}":developer /home/$user/$directory
   done

# Create the symbolic links
    for link in "${links[@]}"; do
       src=$(echo "$link" | cut -d' ' -f1)
       dest=$(echo "$link" | cut -d' ' -f2)
       sudo ln -s "$src" "/home/$user/$dest"
       sudo chown "$user":developer "/home/$user/$dest"

       if [[ ! -L "/home/$user/$dest" ]]; then
           sudo ln -s "$src" "/home/$user/$dest"
       fi

       sudo chown "$user":developer "/home/$user/$dest"
    done
done
