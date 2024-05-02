#!/bin/bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: A set of commands for managing a running Sapiens dedicated server on Linux.

cd $HOME/sapiens-server
# Import your configuration
if [ ! -f "config.sh" ]; then
  echo "Error: config.sh file not found.  Please ensure you run 'install.sh' first."
  exit 1
else
  source config.sh
fi

check_screen() {
    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
}

start_server() {
    check_screen
    if [ $? -eq 0 ]; then
        read -p "It appears there is already a Sapiens server running. Do you want to open the server console instead? (y/n): " choice
        case $choice in
            y|Y)
                open_console
                ;;
            n|N)
                echo "Exiting without starting a new server."
                exit 0
                ;;
            *)
                echo "Invalid choice. Exiting without starting a new session."
                exit 1
                ;;
        esac
    else
        screen -dmS $SCREEN_NAME /bin/bash -c "./start.sh"
        echo "Sapiens world '$WORLD_NAME' started and running in the background."
    fi
}

#Function to kill all running Sapiens Dedicated Server processes and backup the log files.
stop_server() {
    killall linuxServer
    echo "Sapiens world '$WORLD_NAME' has been stopped."
    #screen -S $SCREEN_NAME -p 0 -X stuff "stop^M"
    #TODO Log backup
}

# Function to backup the world folder to the specified backup directory.
backup_server() {
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="sapiens_backup_$TIMESTAMP.tar.gz"
    # Navigate to the parent directory
    cd "$SAPIENS_DIR/players/$SERVER_ID/worlds"
    # Archive the specific world directory, including its name in the archive
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"
}

upgrade_server() {
    steamcmd +runscript ~/sapiens-server/steamupdate.txt
}

open_console() {
    screen -r $SCREEN_NAME
}

case $1 in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 5  # wait for the server to shut down gracefully
        start_server
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
        echo "Usage: $0 {start|stop|restart|backup|upgrade|console}"
        exit 1
        ;;
esac