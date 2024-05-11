#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: A set of commands for managing a running Sapiens dedicated server on Linux.

# Source the required library scripts
cd $HOME/sapiens-server

required_files=("bootstrap.sh" "constants.sh" "manage_world.sh" "manage_server.sh")
for file in "${required_files[@]}"; do
    if ! source "$file"; then
        echo "[ERROR]: Failed to source $file. Ensure the file exists in the script directory and is readable."
        exit 1
    fi
done

# Import the configuration
if [ ! -f "$CONFIG_FILE" ]; then
    logit "ERROR" "$CONFIG_FILE not found.  Please ensure you run 'install.sh' first."
    echo "Error: $CONFIG_FILE not found.  Please ensure you run 'install.sh' first."
    exit 1
else
    logit "DEBUG" "sapiens.sh sourcing $CONFIG_FILE"
    source $CONFIG_FILE
fi



case $1 in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    hardstop)
        hardstop_server
        ;;
    restart)
        stop_server
        sleep 5  # wait for the server to shut down gracefully
        start_server
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

        exit 1
        ;;
esac