#!/bin/bash

chmod +x sapiens.sh start.sh
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install steamcmd
