#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Sapiens Server Manager.

CONFIG_FILE="config.sh"                                 # Name of the config file for the other scripts

# Source the functions file
if ! source functions.sh; then
    echo "Error: Failed to source functions.sh. Ensure the file exists in the script directory and is readable."
    exit 1
fi

# Set a trap to clear the screen when exiting
trap "clear" EXIT

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
if [ ! -f "$CONFIG_FILE" ]; then
    create_config  # Function call to create the configuration file
else
    source $CONFIG_FILE  # Source the existing configuration
fi

# Argument Handling - checks if any argument is provided
if [ "$#" -gt 0 ]; then
    if [ "$1" == "restart" ]; then
        restart_server silent
    else
        echo "Invalid argument: $1"
    fi
    exit 0
else
    # No arguments passed, run the Main Application Loop
    while true; do
        clear
        main_menu_ui
        case $? in
            1)  # Exit the application
                clear
                echo "Sapiens Server Manager exited."
                break
                ;;
            *)  # For all other cases, loop back to the main menu
                ;;
        esac
    done
fi
