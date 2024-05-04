#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup of Steamcmd, Sapiens Server, and configuration file.

# Statics:
CONFIG_FILE="config.sh"                                 # Name of the config file for the other scripts
SCRIPT_DIR="$HOME/sapiens-server"                       # The main script directory
SAPIENS_DIR="$HOME/.local/share/majicjungle/sapiens"    # Where the linuxServer stores data
GAME_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"    # linuxServer install from Steam
BACKUP_DIR="$HOME/sapiens-server/world_backups"         # Destination for world backup files
LOG_BACKUP_DIR="$HOME/sapiens-server/log_backups"       # Destination for log backup files
PLAYERS_DIR="$SAPIENS_DIR/players"                      # Where the server files specifically are.  A "player" dir is a server instance
GAME_CONFIG="$SAPIENS_DIR/serverConfig.lua"             # Path to the serverConfig.lua fil #TODO - auto-update this.
ENET_LOG="$SAPIENS_DIR/enetServerLog.log"               # enet Connection log.
SCREEN_NAME="sapiens-server"                            # Name to be set for the screen session.

# User config Variables:
SERVER_NAME=""
WORLD_NAME=""
WORLD_ID=""
SERVER_ID="sapserver"       # Unless the user picks an existing one, this is what will be used
UDP_PORT=16161              # Default UDP Port for the game
HTTP_PORT=16168             # Default HTTP Port for the game
ADVERTISE="false"           # Default not to advertise

# Source the functions file
if ! source functions.sh; then
    echo "Error: Failed to source functions.sh. Ensure the file exists in the script directory and is readable."
    exit 1
fi

# Splash text to start the interaction with the user.
splash_text

# Check if the script is running as root
check_for_root

# Check if all required dependencies are installed
echo "DEBUG: Calling get_dependency_status"
if ! get_dependency_status; then
    echo "Unable to detect required dependencies. Starting installation..."
    install_dependencies
    patch_steam
fi

# Do a refresh of the sapiens server regardless.
echo "Refreshing and validating Sapiens Server version..."
upgrade_sapiens

if refresh_world_list; then
    echo "---------------------------"
    echo "Please selection an option:"
    echo "---------------------------"
    echo "1. Select an existing world"
    echo "2. Create a new world"
    echo "0. Exit"
    read -p "Enter your choice (1 existing, 2 for new, 0 to Exit): " user_choice

    case $user_choice in
        1)
            select_world
            if [ $? -eq 0 ]; then
                echo "World selected: $WORLD_NAME (ID: $WORLD_ID)"
                # There was an existing world that will be used.

            else
                echo "Failed to select a world."
                exit 1
            fi
            ;;
        2)
            # Placeholder for new world creation
            get_new_server_details
            create_world
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            ;;
    esac
else
    get_new_server_details
    create_world
fi

get_multiplayer_details
get_network_ports
create_config
set_permissions
install_summary

# Ask if they want it started.
if ask_yes_no "Start $WORLD_NAME now"; then
    ./sapiens.sh start
fi
