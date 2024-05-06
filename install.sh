#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup of Steamcmd, Sapiens Server, and configuration file.

CONFIG_FILE="config.sh"                                 # Name of the config file for the other scripts

# Source the functions file
if ! source functions.sh; then
    echo "Error: Failed to source functions.sh. Ensure the file exists in the script directory and is readable."
    exit 1
fi

# Check if the script is running as root
check_for_root

# Check if all required dependencies are installed

if ! get_dependency_status; then
    if whiptail --yesno "The account $(whoami) does not have the necessary software installed to run a Sapiens Server. Do you wish to install it now?" 10 60; then
        # User chose to continue
        install_dependencies    # Install Steamcmd and a few needed utilities
        patch_steam             # Patch for the steam client.
        upgrade_sapiens         # Use steamcmd to update the sapiens executable.
        whiptail --msgbox "Installation Complete!" 8 50
    else
        # User chose not to continue
        whiptail --msgbox "Installation aborted. Exiting now." 8 50
        exit 1
    fi
fi

# Load the Configuration or set defaults
if [ ! -f "config.sh" ]; then
    # Statics:
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
    WORLD_NAME="NO ACTIVE WORLD"
    WORLD_ID=""
    SERVER_ID="sapserver"       # Unless the user picks an existing one, this is what will be used
    UDP_PORT=16161              # Default UDP Port for the game
    HTTP_PORT=16168             # Default HTTP Port for the game
    ADVERTISE="false"           # Default not to advertise

    #create the config file
    create_config
else
    #We already have a configuration, load it
    source config.sh
fi

# Main Application Loop
while true; do
    clear
    main_menu_ui
    case $? in
        1)  # Exit the application
            echo "Closing Sapiens Server manager.  Control your server with the ./sapiens.sh command."
            break
            ;;
        *)  # For all other cases, loop back to the main menu
            ;;
    esac
done