#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: A set of commands for managing a running Sapiens dedicated server on Linux, including installation.

# Ensure the script is running with Bash
if [ -z "$BASH_VERSION" ]; then
  echo "This script must be run with Bash.  Please start with ./sapiens.sh 'command'."
  exit 1
fi

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
    start|stop|hardstop|restart|autorestart|backup|upgrade|console|broadcast|info|worldconfig)
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
        else
            logit "ERROR" "$CONFIG_FILE not found. Please run ./sapiens.sh install to configure an active world." "echo"
            read -p "$(echo -e "${YELLOW}Do you want to run the installation now? (${GREEN}y${YELLOW}/${RED}n${YELLOW}): ${NC}")" choice
            case "$choice" in 
                y|Y ) install_server;;
                n|N|* ) echo -e "${RED}Installation aborted. Exiting...${NC}"; exit 1;;
            esac
        fi
        ;;
esac

case $1 in
    config)
        install_server
        ;;
    worldconfig)
        nano $WORLD_DIR/config.lua
        ;;
    start)
        start_world            # manage_world.sh
        ;;
    stop)
        stop_world             # manage_world.sh
        ;;
    hardstop)
        hardstop_world         # manage_world.sh
        ;;
    restart)
        logit "INFO" "Restarting server"
        broadcast_message "Server is being restarted..."
        stop_world             # manage_world.sh
        start_world            # manage_world.sh.  This will also check that we have the latest Sapiens executable.
        ;;
    autorestart)
        auto_restart "$2"
        ;;
    backup)
        backup_world
        ;;
    upgrade)
        upgrade_server
        ;;
    console)
        open_console
        ;;
    broadcast)
        broadcast_message "$2"
        ;;
    info)
        active_world_summary
        ;;
    *)
        clear
        echo -e "${CYAN}$SCRIPT_NAME${NC}"
        echo -e "${BRIGHT_GREEN}Script Version : $SCRIPT_VERSION${NC}"
        echo -e "${BRIGHT_GREEN}Author         : chillgenxer@chillgenxer.com${NC}"
        echo -e "${BRIGHT_GREEN}GitHub         : $GITHUB_URL${NC}"
        echo ""
        echo -e "Run '${CYAN}./sapiens.sh${NC} ${GREEN}config${NC}' to install the Sapiens server, and to select an active world."
        echo ""
        echo "Usage examples:"
        echo "---------------"
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}start${NC} - Starts the active world in the background."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}console${NC} - Open world's console. To exit without stopping the server hold CTRL and type A D."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}broadcast \"message\"${NC} - Broadcasts a message to the server."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}stop${NC} - Stops the world."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}hardstop${NC} - Stops the world and cancels any autorestart setting."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}restart${NC} - Manually restart the server. Good to use if things are getting laggy."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}autorestart [0-24]${NC} - Automatically restart the world at the specified hour interval, 0 cancels."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}upgrade${NC} - Forced upgrade/validation of the Sapiens server executable from Steam."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}backup${NC} - Stops the world and backs it up to the backup folder."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}config${NC} - Select and configure the active world (does initial install if required)."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}worldconfig${NC} - Opens the game lua configuration file for the active world for editing."
        echo -e "${CYAN}./sapiens.sh${NC} ${GREEN}info${NC} - Show information about the active world."
        echo ""
        echo -e "${BRIGHT_RED}If you have any issues please raise them at ${GREEN}$GITHUB_URL/issues${NC}"
        echo ""
        exit 1
        ;;
esac