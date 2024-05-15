#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: This library script contains functions to manage the running world.

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local current_script=$(basename "${BASH_SOURCE[0]}")
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    logit "INFO" "Attempt to run $current_script directly detected.  Please use sapiens.sh for all operations."
    exit 1
fi

server_status() {
    # Checks to see if there is an active screen session, implying the server is up
    #TODO Should probably check for the linuxServer process too to make this more robust

    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
    local status=$?  # Capture the exit code of the grep command

    # Log the status before exiting the function
    if [ $status -eq 0 ]; then
        logit "INFO" "server_status is reporting a screen session $SCREEN_NAME found, so server is probably running."
    else
        logit "WARN" "server_status was unable to find a screen session named $SCREEN_NAME, server is probably not running."
    fi

    return $status  # Explicitly return the captured exit code
}

# Starts the dedicated server in a screen session
start_server() {
    server_status
    if [ $? -eq 0 ]; then
        read -p "It appears there is already a Sapiens server running. Do you want to open the server console instead? (y/n): " choice
        case $choice in
            y|Y)
                open_console
                ;;
            n|N)
                logit "INFO" "start_server: Exiting without starting a new server." "echo"
                exit 0
                ;;
            *)
                logit "WARN" "start_server: Invalid choice. Exiting without starting a new session." "echo"
                exit 1
                ;;
        esac
    else
        screen -dmS $SCREEN_NAME /bin/bash -c "./startworld.sh"
        logit "INFO" "Sapiens world '$WORLD_NAME' started in the background. View the console with ./sapiens.sh console." "echo"
    fi
}

# Stop the running server and ensure the screen session is terminated
stop_server() {
    # Valid arguments
    local silent_mode=$1    # Accepts an argument "silent" to set silent mode
    local shutdown_wait=5   # TODO - Add this to configurable options

    # Attempt to shut down the server cleanly via screen.
    screen -S $SCREEN_NAME -X stuff 'stop^M'
    
    # Wait for it to finish
    if [ "$silent_mode" != "silent" ]; then
        logit "INFO" "Shutting down $WORLD_NAME..."
        sleep $shutdown_wait
    else
        sleep $shutdown_wait
    fi

    # Check and terminate the screen session if it still exists
    if screen -list | grep -q "$SCREEN_NAME"; then
        screen -S "$SCREEN_NAME" -X quit
    fi

    # Provide feedback about screen termination
    if [ "$silent_mode" != "silent" ]; then
        logit "INFO" "World '$WORLD_NAME' has been stopped."
    fi
}

#Stop the server, and cancel the restart timer
hardstop_server(){
    if pgrep -x "linuxServer" > /dev/null; then
        killall linuxServer
    fi
    logit "INFO" "'$WORLD_NAME' has been hard stopped." "echo"
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
    tar -czf "$WORLD_BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"
}

# Use steamcmd to upgrade the Sapiens Dedicated Server
upgrade_server() {
    logit "INFO" "Running: steamcmd +runscript ~/sapiens-server/steamupdate.txt"
    steamcmd +runscript $HOME/sapiens-server/steamupdate.txt
}

# Open the screen session to see the server console
open_console() {
    # Call server_status to see if the screen session exists
    if server_status; then
        # If a screen session is found, resume it
        screen -r $SCREEN_NAME
    else
        # Let the user know.
        logit "WARN" "The console for $WORLD_NAME was not found [screen=$SCREEN_NAME]. Please start the server first."
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