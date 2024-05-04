#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: A set of commands for managing a running Sapiens dedicated server on Linux.

# Import the configuration
if [ ! -f "config.sh" ]; then
  echo "Error: config.sh file not found.  Please ensure you run 'install.sh' first."
  exit 1
else
  source config.sh
  cd $SCRIPT_DIR
fi

# Checks to see if there is an active screen session, implying the server is up
check_screen() {
    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
}

# Starts the dedicated server in a screen session
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
        echo "Sapiens world '$WORLD_NAME' started in the background. View the console with ./sapiens.sh console."
    fi
}

#Function to kill all running Sapiens Dedicated Server processes and backup the log files.
stop_server() {
    if pgrep -x "linuxServer" > /dev/null; then
        killall linuxServer
        echo "'$WORLD_NAME' has been stopped.  If you intend to keep it stopped, please ensure you run ./sapiens autorestart 0 to disable any autorestarts."
    else
        echo "'$WORLD_NAME' was already stopped."
    fi
}

#Stop the server, and cancel the restart timer
hardstop_server(){
    if pgrep -x "linuxServer" > /dev/null; then
        killall linuxServer
        echo "'$WORLD_NAME' has been hard stopped, and autorestart has been turned OFF."
    else
        auto_restart "0"
    fi

    echo "'$WORLD_NAME' has been hard stopped, and autorestart has been turned OFF."
}

# Function to backup the world folder to the specified backup directory.
backup_server() {
 
    echo "Stopping server if necessary..."
    stop_server

    echo "Backing up the world '$WORLD_NAME'..."
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="sapiens_backup_$TIMESTAMP.tar.gz"
    cd "$SAPIENS_DIR/players/$SERVER_ID/worlds"
    # Archive the specific world directory, including its name in the archive
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"
    
}

# Use steamcmd to upgrade the Sapiens Dedicated Server
upgrade_server() {
    steamcmd +runscript ~/sapiens-server/steamupdate.txt
}

# Open the screen session to see the server console
open_console() {
    # Call check_screen to see if the screen session exists
    if check_screen; then
        # If a screen session is found, resume it
        screen -r $SCREEN_NAME
    else
        # Let the user know.
        echo "The console for $WORLD_NAME was not found [screen=$SCREEN_NAME]. Please start the server first."
    fi
}

# Set a cronjob to restart the Sapiens server.
auto_restart() {
    if [[ "$1" == "0" ]]; then
        # Remove the existing cron job if the interval is set to 0
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/sapiens.sh restart") | crontab -
        echo "Auto-restart has been disabled."
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
        INTERVAL="$1"
        CRON_JOB="*/$INTERVAL * * * * $SCRIPT_DIR/sapiens.sh restart"
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/sapiens.sh restart"; echo "$CRON_JOB") | crontab -
        echo "$WORLD_NAME will restart every $INTERVAL minutes."
    else
        echo "Error: Interval must be a number"
        exit 1
    fi
}

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
        echo "Sapiens Server Manager"
        echo "chillgenxer@chillgenxer.com"
        echo ""
        echo "Usage examples:"
        echo "./sapiens.sh start - starts your world in the background."
        echo "./sapiens.sh console - Bring the running world's console. To exit without stopping the server hold CTRL and type A D."        
        echo "./sapiens.sh stop - stops your world."
        echo "./sapiens.sh restart - Manually restart the server. Good to use if things are getting laggy."
        echo "./sapiens.sh autorestart [minutes] - Automatically restart the world at the specified interval."
        echo "./sapiens.sh upgrade - This will update you to the latest version of the Sapiens server."
        echo "./sapiens.sh backup - Stops the world and backs it up to the backup folder."

        exit 1
        ;;
esac