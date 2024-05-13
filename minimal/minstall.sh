#!/usr/bin/env bash
# A basic script for getting a running Sapiens linuxServer

# You need to update this to the path of where ever you put steamupdate.txt
STEAM_UPDATE_SCRIPT="$HOME/sapiens-server/minimal/steamupdate.txt"

echo "Installing steamcmd..."

# Add the Steam repository and prep for install
sudo add-apt-repository -y multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y steamcmd

# Install Sapiens
steamcmd +runscript $STEAM_UPDATE_SCRIPT

echo "Patching mislocated steamclient.so..."

# Create directory and link libraries
link_path="$HOME/.steam/sdk64/steamclient.so"
target_path="$HOME/.local/share/Steam/steamcmd/linux64/steamclient.so"

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$link_path")"

# Check if the symbolic link already exists
if [ ! -L "$link_path" ]; then
    # Create the symbolic link if it does not exist
    ln -s "$target_path" "$link_path"
    echo "Steam client patch complete."
else
    echo "Symbolic link already exists, no need to patch."
fi

echo "Sapiens linuxServer installation complete."
