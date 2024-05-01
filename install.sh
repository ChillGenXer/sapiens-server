#!/bin/bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup of Steamcmd, Sapiens Server, and configuration file.

# Make necessary scripts executable
chmod +x sapiens.sh start.sh

# Add the multiverse repository
sudo add-apt-repository multiverse

# Add i386 architecture
sudo dpkg --add-architecture i386

# Update package lists
sudo apt update

# Install steamcmd
sudo apt install steamcmd

# Run steamcmd with preconfigured Sapiens Server update script
steamcmd +runscript ~/sapiens-server/steamupdate.txt

# Create directory and link libraries
mkdir -p ~/.steam/sdk64
cd ~/.steam/sdk64/
ln -s ../steam/steamcmd/linux64/steamclient.so steamclient.so

# Check if config.sh exists, if not, create it
cd ~/sapiens-server
if [ ! -f "$CONFIG_FILE" ]; then
    cat <<EOF >"$CONFIG_FILE"
#!/bin/bash

# Location of where the server executable is located
GAME_DIR="/home/YOUR_LINUX_USER/.local/share/Steam/steamcmd/sapiens"

# Location of where the world is
WORLD_DIR="/home/YOUR_LINUX_USER/.local/share/majicjungle/sapiens/players/PLAYER_FOLDER_NAME/worlds/WORLD_FOLDER_NAME"

# Folder where the backup command will send your world archive
BACKUP_DIR="/home/YOUR_LINUX_USER/sapiens-server/world_backups"

# Folder where the logs will be archived when you stop the server.
LOG_BACKUP_DIR="/home/YOUR_LINUX_USER/sapiens-server/log_backups"

# World Name.  Make sure to use the EXACT name you used when initializing your world with linuxServer --new "YourWorldName"
WORLD_NAME="YourWorldName"

# Network settings.  If exposing to the internet you will have to open up 2 UDP ports, +1 above the specified UDP_PORT
# and the HTTP port, so in the case of the defaults you will need to port forward 16161, 16162, 16168
UDP_PORT=16161
HTTP_PORT=16168

# Screen name for the server session
SCREEN_NAME="sapiens-server"
EOF
fi