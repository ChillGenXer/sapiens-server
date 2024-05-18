#!/usr/bin/env bash
# A basic script for getting a running Sapiens linuxServer

echo "Installing steamcmd..."

# Add the Steam repository and prep for install
sudo add-apt-repository -y multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y steamcmd

# Install Sapiens
steamcmd +force_install_dir sapiens +login anonymous +app_update 2886350 validate +quit

echo "Sapiens linuxServer installation complete."
