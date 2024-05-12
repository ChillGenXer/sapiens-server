#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Installation script that ensures dependencies are present and configures
# a world server to run.

# Source the required library scripts
cd $HOME/sapiens-server
required_files=("bootstrap.sh" "constants.sh" "manage_world.sh" "manage_server.sh" "database.sh")
for file in "${required_files[@]}"; do
    if ! source "$file"; then
        echo "[ERROR]: Failed to source $file. Ensure the file exists in the script directory and is readable."
        exit 1
    fi
done

# Do initial checks to see if something needs to be installed.
logit "DEBUG" "*********************** install.sh started ***********************"
logit "DEBUG" "Calling check_for_root"; check_for_root

# Show the welcome screen
splash_text

# Check to see if the software dependences are in place
if ! dependencies_installed; then
    logit "INFO" "Dependency check failed on linux account $(whoami)."
    echo "The account $(whoami) does not have the necessary software installed to run the Sapiens linuxServer."
    if ! yesno "Would you like to install it now?"; then
        echo "Installation aborted."
        logit "INFO" "Dependency installation aborted by user."
        exit 0
    else
        logit "DEBUG" "Calling install_dependencies"
        install_dependencies    # Install Steamcmd and the other required dependencies
        logit "DEBUG" "Calling patch_steam"
        patch_steam             # Patch for the steam client.
        logit "DEBUG" "Calling upgrade_sapiens"
        upgrade_sapiens         # Use steamcmd to update the sapiens executable.
        echo "Sapiens Server Manager installation successfully complete!"
        read -n 1 -s -r -p "Press any key to continue"
        echo ""  # Move to the next line after the key press
    fi
fi

# Check to see in the linuxServer executable is present
if ! sapiens_installed; then
    logit "INFO" "Sapiens linuxServer not found.  Installing."
    echo "Sapiens linuxServer not found.  Installing."
    upgrade_sapiens
fi

# Ensure the needed directories exist
config_dir $BACKUP_DIR
config_dir $LOG_BACKUP_DIR
set_permissions
add_to_path $SCRIPT_DIR # Add the script directory to the path.

while true; do
    # Call installed_worlds and store the count
    world_count=$(installed_worlds)

    echo -e "${BRIGHT_CYAN}-------------------------------------------------------${NC}"
    # Check if the world count is greater than zero
    if [[ $world_count -gt 0 ]]; then
        echo -e "${BRIGHT_GREEN}***** $world_count detected installed worlds *****${NC}\n"
        show_installed_worlds "clean"
    else
        echo -e "${RED}No installed worlds detected.${NC}"
    fi
    echo -e "${BRIGHT_CYAN}-------------------------------------------------------${NC}"
    echo -e "${BRIGHT_YELLOW}1. Make an existing world active${NC}"
    echo -e "${BRIGHT_YELLOW}2. Create a new world${NC}"
    echo -e "${BRIGHT_YELLOW}0. Exit${NC}"
    echo -e "${BRIGHT_CYAN}-------------------------------------------------------${NC}"
    read -p "Enter your choice (1 existing, 2 for new, 0 to Exit): " user_choice

    case $user_choice in
        1)
            select_world
            if [ $? -eq 0 ]; then
                echo "World selected : $WORLD_NAME"
                echo "World ID       : $WORLD_ID"
                echo "Server ID      : $SERVER_ID"
                logit "INFO" "World selected: $WORLD_NAME"
                logit "INFO" "World ID      : $WORLD_ID"
                logit "INFO" "Server ID     : $SERVER_ID"
                # There was an existing world that will be used.
            else
                echo "Failed to select a world."
                logit "DEBUG" "User made an invalid select_world menu choice."
                exit 1
            fi
            ;;
        2)
            # Calls function to create a new world
            WORLD_ID=$(create_world)
            if [[ $WORLD_ID ]]; then
                logit "INFO" "World created and selected: $WORLD_NAME (ID: $WORLD_ID)"
            else
                logit "ERROR" "Failed to create a new world."
                continue # Skip the menu refresh if world creation failed
            fi
            ;;
        0)
            echo "Exiting program."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            ;;
    esac

    # Break loop if not creating a new world to avoid showing the menu again unnecessarily
    if [[ "$user_choice" != "2" ]]; then
        break
    fi
done

get_active_server_details
create_config
#install_summary

# Ask if they want it started.
# if yesno "Start $WORLD_NAME now"; then
#    ./sapiens.sh start
# fi
