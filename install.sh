#!/bin/bash

chmod +x sapiens.sh start.sh
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install steamcmd
steamcmd +runscript ~/sapiens-server/steamupdate.txt
mkdir ~/.steam/sdk64
cd ~/.steam/sdk64/
ln -s ../steam/steamcmd/linux64/steamclient.so steamclient.so
# Define the directory to add to the PATH
DIR="$HOME/sapiens-server"

# Check if the directory is already in the PATH
if [[ ":$PATH:" != *":$DIR:"* ]]; then
    # Add the directory to the PATH in .bashrc if it's not already included
    echo "export PATH=\"\$PATH:$DIR\"" >> ~/.bashrc
    
    # Source the .bashrc to update the current session
    source ~/.bashrc

    echo "Directory $DIR added to PATH."
else
    echo "Directory $DIR is already in PATH."
fi
