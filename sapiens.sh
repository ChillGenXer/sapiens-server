#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: A set of commands for managing a running Sapiens dedicated server on Linux, including installation.

# Source the required library scripts
cd $HOME/sapiens-server

required_files=("constants.sh" "bootstrap.sh" "manage_world.sh" "manage_server.sh")
for file in "${required_files[@]}"; do
    if ! source "$file"; then
        echo "[ERROR]: Failed to source $file. Ensure the file exists in the script directory and is readable."
        exit 1
    fi
done

# Some of the command line arguments require the config file to be set.  If it is not found, exit with an error.
case $1 in
    start|stop|hardstop|restart|autorestart|backup|upgrade|console)
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
        else
            logit "ERROR" "$CONFIG_FILE not found. Please run ./sapiens.sh install to configure an active world."
            exit 1
        fi
        ;;
esac

case $1 in
    install)
        logit "DEBUG" "*********************** install.sh started ***********************"
        logit "DEBUG" "Calling check_for_root"; check_for_root

        # Show the welcome screen
        splash_text

        # Check to see if the software dependencies are in place
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

        # Check to see if the linuxServer executable is present
        if ! sapiens_installed; then
            logit "INFO" "Sapiens linuxServer not found.  Installing."
            echo "Sapiens linuxServer not found.  Installing."
            upgrade_sapiens
        fi

        # Ensure the needed directories exist
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
        ;;
    start)
        start_server            # manage_world.sh
        ;;
    stop)
        stop_server             # manage_world.sh
        ;;
    hardstop)
        hardstop_server         # manage_world.sh
        ;;
    restart)
        logit "INFO" "Restarting server"
        stop_server             # manage_world.sh
        sleep 5  # wait for the server to shut down gracefully
        start_server            # manage_world.sh
        ;;
    autorestart)
        auto_restart "$2"
        ;;
    backup)
        backup_server
        ;;
    upgrade)
        upgrade_server
        ;;
    console)
        open_console
        ;;    
    *)
        echo "$SCRIPT_NAME"
        echo "Script Version: $SCRIPT_VERSION"
        echo "Author: chillgenxer@chillgenxer.com"
        echo "GitHub: $GITHUB_URL"
        echo ""
        echo "Usage examples:"
        echo "./sapiens.sh start - starts your world in the background."
        echo "./sapiens.sh console - Bring the running world's console. To exit without stopping the server hold CTRL and type A D."        
        echo "./sapiens.sh stop - stops your world."
        echo "./sapiens.sh restart - Manually restart the server. Good to use if things are getting laggy."
        echo "./sapiens.sh autorestart [hours] - Automatically restart the world at the specified hour interval."
        echo "./sapiens.sh upgrade - This will update you to the latest version of the Sapiens server."
        echo "./sapiens.sh backup - Stops the world and backs it up to the backup folder."
        echo "./sapiens.sh install - Installs dependencies and configures the Sapiens server."

        exit 1
        ;;
esac