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
    # Attempt to do it cleanly.
    screen -S $SCREEN_NAME -X stuff 'stop^M'

    sleep 5

    # Check if it's really down, and if not kill the process.
    if pgrep -x "linuxServer" > /dev/null; then
        killall linuxServer
    fi

    echo "'$WORLD_NAME' has been stopped.  If you intend to keep it stopped, please run ./sapiens.sh hardstop to keep it from restarting."
}

#Stop the server, and cancel the restart timer
hardstop_server(){
    if pgrep -x "linuxServer" > /dev/null; then
        killall linuxServer
    fi
    echo "'$WORLD_NAME' has been hard stopped."
    auto_restart "0"
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

# Set a cronjob to restart the Sapiens server at specified hourly intervals or disable the restart.
auto_restart() {
    if [[ "$1" == "0" ]]; then
        # Remove the existing cron job if the interval is set to 0
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/sapiens.sh restart") | crontab -
        echo "Auto-restart has been disabled."
    elif [[ "$1" =~ ^[1-9]$|^1[0-9]$|^2[0-4]$ ]]; then
        INTERVAL="$1"
        CRON_JOB="0 */$INTERVAL * * * $SCRIPT_DIR/sapiens.sh restart"
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/sapiens.sh restart"; echo "$CRON_JOB") | crontab -
        echo "$WORLD_NAME will restart every $INTERVAL hour(s)."
    else
        echo "Error: Interval must be a number of hours between 1 and 24 or 0 to disable."
        exit 1
    fi
}