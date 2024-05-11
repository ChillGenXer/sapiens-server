#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Installation script that ensures dependencies are present and configures
# a world server to run.

# Source the required library scripts
cd $HOME/sapiens-server

required_files=("bootstrap.sh" "constants.sh" "manage_world.sh" "manage_server.sh")
for file in "${required_files[@]}"; do
    if ! source "$file"; then
        echo "[ERROR]: Failed to source $file. Ensure the file exists in the script directory and is readable."
        exit 1
    fi
done

# Do initial checks to see if something needs to be installed.
logit "DEBUG" "*********************** install.sh started ***********************"
logit "DEBUG"  "Calling startup_sequence"
startup_sequence    # From bootstrap.sh

if refresh_worldlist; then
    logit "INFO" "Worlds found.  Prompting user for selection."
    echo "------------------------------------"
    echo "Please select an option:"
    echo "------------------------------------"
    echo "1. Configure an existing world"
    echo "2. Create and configure a new world"
    echo "0. Exit"
    echo "------------------------------------"
    read -p "Enter your choice (1 existing, 2 for new, 0 to Exit): " user_choice

    case $user_choice in
        1)
            select_world
            if [ $? -eq 0 ]; then
                echo "World selected: $WORLD_NAME (ID: $WORLD_ID)"
                logit "INFO" "World selected: $WORLD_NAME (ID: $WORLD_ID)"
                # There was an existing world that will be used.

            else
                echo "Failed to select a world."
                logit "DEBUG" "User made an invalid select_world menu choice."
                exit 1
            fi
            ;;
        2)
            # Placeholder for new world creation
            WORLD_ID=$(create_world)
            logit "INFO" "World created, Active World WORLD_ID set to $WORLD_ID"
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

#get_multiplayer_details
#get_network_ports
#create_config
#set_permissions
#install_summary

# Ask if they want it started.
if yesno "Start $WORLD_NAME now"; then
    ./sapiens.sh start
fi

# First function that will be run to check if all the bits are here
startup_sequence(){
    
    # Check if the script is running as root
    logit "DEBUG" "Calling check_for_root"
    check_for_root

    # Load the Configuration or set defaults
    if [ ! -f "$CONFIG_FILE" ]; then
        logit "DEBUG" "Missing config file, calling create_config"
        create_config  # Function call to create the configuration file
    else
        source $CONFIG_FILE  # Source the existing configuration
    fi

    # Show the welcome screen
    splash_text

    # Check if all required dependencies are installed
    if ! get_dependency_status; then
        logit "INFO" "Dependency check failed, starting install."
        echo "The account $(whoami) does not have the necessary software installed."
        if ! yesno "Would you like to install it now?"; then
            echo "Installation aborted."
            logit "INFO" "Dependency installation aborted by user."
            exit 0
        fi

        logit "DEBUG" "Calling install_dependencies"
        install_dependencies    # Install Steamcmd and the other required dependencies
        logit "DEBUG" "Calling patch_steam"
        patch_steam             # Patch for the steam client.
        logit "DEBUG" "Calling upgrade_sapiens"
        upgrade_sapiens         # Use steamcmd to update the sapiens executable.
        logit "DEBUG" "Calling create_config"
        create_config           # Generate a new config to get the version number.
        add_to_path $SCRIPT_DIR # Add the script directory to the path.

        echo "Sapiens Server Manager installation successfully complete!"
        read -n 1 -s -r -p "Press any key to continue"
        echo ""  # Move to the next line after the key press
    fi
    upgrade_sapiens         # Use steamcmd to update the sapiens executable.
}

# Runs on exit
shutdown_sequence() {
    logit "DEBUG" "shutdown_sequence initiated."
    
    echo "Sapiens Linux Server Helper Scripts Version $VERSION" 
    echo "Thanks for using these scripts.  If you encounter any issues"
    echo "please raise them at https://github.com/ChillGenXer/sapiens-server/issues ."
    echo ""
}
