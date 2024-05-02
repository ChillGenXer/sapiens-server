#!/bin/bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup of Steamcmd, Sapiens Server, and configuration file.

# Initialize all our global variables.  Statics first, then the ones that will change.

# Statics:
CONFIG_FILE="config.sh"
SAPIENS_DIR="$HOME/.local/share/majicjungle/sapiens"    # Where the linuxServer stores data
GAME_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"    # linuxServer install from Steam
BACKUP_DIR="$HOME/sapiens-server/world_backups"         # Destination for world backup files
LOG_BACKUP_DIR="$HOME/sapiens-server/log_backups"       # Destination for log backup files
PLAYERS_DIR="$SAPIENS_DIR/players"                      # Where the server files specifically are.  A "player" dir is a server instance
GAME_CONFIG="$SAPIENS_DIR/serverConfig.lua"             # Path to the serverConfig.lua fil #TODO - auto-update this.
ENET_LOG="$SAPIENS_DIR/enetServerLog.log"               # enet Connection log.
VERSION="0.3"
SCREEN_NAME="sapiens-server"

# User config Variables:
SERVER_NAME=""
WORLD_NAME=""
WORLD_ID=""
SERVER_ID="sapserver" # Unless the user picks an existing one, this is what will be used
UDP_PORT=16161
HTTP_PORT=16168
ADVERTISE="false"

# Bring in our functions
source functions.sh

# Check if the script is running as root
check_for_root

# Splash text to start the interaction with the user.
splash_text

# Check to see if there are existing worlds, and ask the user if they want to use one of them.
if select_world; then
    # There was an existing world that will be used.  Generate the config file and exit.
    get_network_ports   # Ask the user for the ports
    create_config       # Create the configuration file
    set_permissions     # Set permissions for the scripts
    install_summary     # Summarize the new server
    exit 0
fi

# Let's get the details to set up a new world.
get_new_server_details
get_network_ports

#Install dependencies and install/upgrade the Sapiens dedicated server
# TODO - Check that this all went down ok
install_dependencies
upgrade_sapiens
patch_steam

# create the new world
create_world

# create the configuration file, set permissions and exit.
create_config
set_permissions
install_summary
