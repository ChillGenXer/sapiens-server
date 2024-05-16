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
    install)
        install_server
        ;;
    start)
        upgrade_server          # Check to see if we have the latest version.
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
        clear
        echo "$SCRIPT_NAME"
        echo "Script Version: $SCRIPT_VERSION"
        echo "Author: chillgenxer@chillgenxer.com"
        echo "GitHub: $GITHUB_URL"
        echo ""
        echo "Run './sapiens.sh install' to install dependencies and the Sapiens Server."
        echo ""
        echo "Usage examples:"
        echo "---------------"
        echo "./sapiens.sh start - starts your world in the background."
        echo "./sapiens.sh console - Bring the running world's console. To exit without stopping the server hold CTRL and type A D."        
        echo "./sapiens.sh stop - Stops the world."
        echo "./sapiens.sh hardstop - Stops the world and cancels any autorestart setting."
        echo "./sapiens.sh restart - Manually restart the server. Good to use if things are getting laggy."
        echo "./sapiens.sh autorestart [0-24] - Automatically restart the world at the specified hour interval, 0 cancels."
        echo "./sapiens.sh upgrade - Upgrade to the latest version of the Sapiens server executable from Steam."
        echo "./sapiens.sh backup - Stops the world and backs it up to the backup folder."
        echo ""
        exit 1
        ;;
esac