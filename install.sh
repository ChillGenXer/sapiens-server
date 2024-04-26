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
