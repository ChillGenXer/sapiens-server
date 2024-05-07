#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file to externalize server interaction functions.

#Server state object
declare -A SERVER_STATE=(
)

# Open the screen session to see the server console
open_console() {
    # Call server_status to see if the screen session exists
    if server_status; then
        # If a screen session is found, resume it
        dialog --clear --msgbox "You are about to open the console for $WORLD_NAME.  Once open, to exit the console without stopping the server hold CTRL then press A + D." 10 70
        screen -r $SCREEN_NAME
    else
        # Let the user know.
        dialog --clear --msgbox "The console for $WORLD_NAME was not found [screen=$SCREEN_NAME]. Please start the server first." 10 70
    fi
}

# Starts the dedicated server in a screen session
start_server() {
    local silent_mode=$1  # Accepts an argument to determine silent mode
    rm "no-restart.flag" 

    server_status
    
    if [ $? -eq 0 ]; then
        # Server is already running
        if [ "$silent_mode" != "silent" ]; then
            if (dialog --clear --title "Server Console" --yesno "It appears there is already a Sapiens server running. Do you want to open the server console instead?" 10 60) then
                open_console
            fi
        fi
    else
        # Start the server in a detached screen
        #./start.sh
        screen -dmS $SCREEN_NAME /bin/bash -c "./start.sh"
        if [ "$silent_mode" != "silent" ]; then
            dialog --clear --msgbox "Sapiens world '$WORLD_NAME' has been started!" 10 50
        fi
    fi
}

# Stop the running server and ensure the screen session is terminated
stop_server() {
    local silent_mode=$1  # Accepts an argument to determine silent mode

    # First, stop the server processes using the usual method
    if pgrep -x "linuxServer" > /dev/null; then
        touch "no-restart.flag"  # Set a flag to prevent restart in start.sh
        killall linuxServer
        
        # Provide user feedback if not in silent mode
        if [ "$silent_mode" != "silent" ]; then
            dialog --clear --msgbox "'$WORLD_NAME' has been stopped. If you intend to keep it stopped until you manually start it again, please do a hard stop from the menu." 10 50
        fi
    else
        if [ "$silent_mode" != "silent" ]; then
            dialog --clear --msgbox "'$WORLD_NAME' was already stopped." 10 50
        fi
    fi

    # Check and terminate the screen session if it exists
    if screen -list | grep -q "$SCREEN_NAME"; then
        screen -S "$SCREEN_NAME" -X quit

        # Provide feedback about screen termination
        if [ "$silent_mode" != "silent" ]; then
            dialog --clear --msgbox "Screen session '$SCREEN_NAME' has been terminated." 10 50
        fi
    fi
}

# Stop and start a running server.
restart_server() {
    local silent_mode=$1  # Accepts an argument to determine silent mode
    if [ "$silent_mode" != "silent" ]; then
        stop_server silent
        sleep 5  # wait for the server to shut down gracefully
        start_server silent
    else
        stop_server
        sleep 5  # wait for the server to shut down gracefully
        start_server
    fi
}

#Stop the server, and cancel the restart timer
hardstop_server(){
    if pgrep -x "linuxServer" > /dev/null; then
        killall linuxServer
    fi
    auto_restart "0" 
    dialog --clear --msgbox "'$WORLD_NAME' has been stopped and autorestart cancelled." 10 50
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

# Function to backup the world folder to the specified backup directory.
backup_server() {
    # TODO Error handling
    # Ensure that the server is stopped.
    stop_server silent

    echo "Backing up the world '$WORLD_NAME'..."
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="sapiens_backup_$TIMESTAMP.tar.gz"
    cd "$SAPIENS_DIR/players/$SERVER_ID/worlds"
    # Archive the specific world directory, including its name in the archive
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"

    dialog --clear --msgbox "'$WORLD_NAME' has been backed up.  Don't forget to restart your world." 10 70
}

# Checks to see if there is an active screen session, implying the server is up
server_status() {
    #TODO Should probably check for the linuxServer process too to make this more robust
    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
    return $?  # Explicitly return the exit code of the grep command
}