#!/bin/bash

set -e

# Check if font directory exists
if [ ! -d "/usr/share/fonts/truetype/firacode" ]; then
    echo "Font directory does not exist. Creating now..."
    # Create necessary directories
    mkdir -p /usr/share/fonts/truetype/firacode
    mkdir -p /tmp/firacode

    # Download font
    echo "Downloading font..."
    wget -O /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip

    # Unzip font
    echo "Unzipping font..."
    unzip /tmp/FiraCode.zip -d /tmp/firacode

    # Move font files to target directory
    echo "Moving font files..."
    mv /tmp/firacode/*.ttf /usr/share/fonts/truetype/firacode/

    # Update font cache
    echo "Updating font cache..."

fc-cache -fv

else
    echo "Font directory already exists. Skipping directory creation and font download."
fi

echo "Done!"

