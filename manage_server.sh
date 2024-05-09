#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file library to manage the server interaction functions.

# Open the screen session to see the server console
open_console() {
    # Call server_status to see if the screen session exists
    if server_status; then
        # If a screen session is found, resume it
        dialog --colors --clear --msgbox \
            " You are about to open the console for \Zb$WORLD_NAME\ZB. Once open, to exit the console without stopping the server \Zb\Z1hold CTRL then press A + D\Zn\ZB." 0 0
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
    # Valid arguments
    local silent_mode=$1    # Accepts an argument "silent" to set silent mode
    local shutdown_wait=5   # TODO - Add this to configurable options

    # Attempt to shut down the server cleanly via screen.
    screen -S $SCREEN_NAME -X stuff 'stop^M'
    
    # Wait for it to finish
    if [ "$silent_mode" != "silent" ]; then
        sleep_ui "Shutting down $WORLD_NAME..." $shutdown_wait
    else
        sleep $shutdown_wait
    fi

    # Check and terminate the screen session if it still exists
    if screen -list | grep -q "$SCREEN_NAME"; then
        screen -S "$SCREEN_NAME" -X quit
    fi

    # Provide feedback about screen termination
    if [ "$silent_mode" != "silent" ]; then
        dialog --clear --msgbox "World $WORLD_NAME has been stopped." 10 50
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

# Checks to see if there is an active screen session, implying the server is up
server_status() {
    #TODO Should probably check for the linuxServer process too to make this more robust
    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
    return $?  # Explicitly return the exit code of the grep command
}

# Send a chat message to the server
send_server_message(){
    local message = $1
    local clientName = "SERVER BROADCAST"   # Hardcode for now
    screen -S "$SCREEN_SESSION" -p 0 -X stuff $'server:callClientFunctionForAllClients("chatMessageRecieved", {text="'$message'", clientName = "'$clientName'"})\r'
}
