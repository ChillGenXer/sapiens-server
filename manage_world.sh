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

# Attempts to determine if the server is running.
world_status() {
    # Check if the world running file exists
    if [ ! -f "$WORLD_RUNNING_FILE" ]; then
        logit "WARN" "world_status: $WORLD_RUNNING_FILE does not exist, server is not running."
        return 1
    fi

    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
    local screen_status=$?  # Capture the exit code of the grep command

    # Check if the linuxServer process is running
    pgrep -x "linuxServer" > /dev/null
    local process_status=$?  # Capture the exit code of the pgrep command

    # Determine the combined status based on the file, screen session, and process
    if [ $screen_status -eq 0 ] && [ $process_status -eq 0 ]; then
        logit "INFO" "world_status: $WORLD_RUNNING_FILE exists, screen session $SCREEN_NAME found, and linuxServer process is running. Server is running."
        return 0
    elif [ $screen_status -eq 0 ] && [ $process_status -ne 0 ]; then
        logit "WARN" "world_status: $WORLD_RUNNING_FILE exists, screen session $SCREEN_NAME found, but linuxServer process is not running."
        return 2
    elif [ $screen_status -ne 0 ] && [ $process_status -eq 0 ]; then
        logit "WARN" "world_status: $WORLD_RUNNING_FILE exists, but screen session $SCREEN_NAME is not found, and linuxServer process is running."
        return 3
    else
        logit "WARN" "world_status: $WORLD_RUNNING_FILE exists but neither screen session $SCREEN_NAME nor linuxServer process are running."
        return 1
    fi
}

# Starts the dedicated server in a screen session
start_world() {
    world_status
    if [ $? -eq 0 ]; then
        read -p "$(echo -e "${CYAN}It appears there is already a Sapiens server running. Do you want to open the server console instead? (${GREEN}y${YELLOW}/${RED}n${YELLOW}): ${NC}")" choice
        case $choice in
            y|Y)
                logit "INFO" "start_world: Running open_console"
                open_console
                ;;
            n|N)
                logit "INFO" "start_world: Exiting without starting a new server." "echo"
                exit 0
                ;;
            *)
                logit "WARN" "start_world: Taking '$choice' to mean quit without starting a new session." "echo"
                exit 1
                ;;
        esac
    else
        screen -dmS $SCREEN_NAME /bin/bash -c "./startworld.sh"
        logit "INFO" "start_world: Sapiens world '$WORLD_NAME' started in the background. View the console with ./sapiens.sh console." "echo"
    fi
}

# Stop the running server and ensure the screen session is terminated
stop_world() {
    local silent_mode=$1    # Accepts an argument "silent" to set silent mode
    local max_wait_time=$SHUTDOWN_WAIT
    local wait_interval=1
    local elapsed_time=0

    # Attempt to shut down the server cleanly via screen.
    screen -S "$SCREEN_NAME" -p 0 -X stuff "stop$(printf \\r)" >/dev/null 2>&1

    logit "INFO" "stop_world: Shutting down $WORLD_NAME..."
    if [ "$silent_mode" != "silent" ]; then
        echo "Shutting down $WORLD_NAME..."
    fi

    # Loop to check if the screen session is still running
    while screen -list | grep -q "$SCREEN_NAME"; do
        if [ $elapsed_time -ge $max_wait_time ]; then
            logit "WARN" "stop_world: Screen session $SCREEN_NAME did not stop within $max_wait_time seconds. Proceeding to forcefully kill linuxServer process."
            break
        fi
        sleep $wait_interval
        elapsed_time=$((elapsed_time + wait_interval))
    done
    logit "DEBUG" "stop_world: screen session exit wait = $elapsed_time seconds."

    # If screen session is still running, forcefully kill the linuxServer process
    if screen -list | grep -q "$SCREEN_NAME"; then
        killall "linuxServer"
        logit "WARN" "stop_world: Attempting to kill linuxServer process."

        elapsed_time=0
        # Loop to check if the linuxServer process is still running
        while pgrep -x "linuxServer" > /dev/null; do
            if [ $elapsed_time -ge $max_wait_time ]; then
                logit "ERROR" "stop_world: linuxServer process did not terminate within $max_wait_time seconds after killall command."
                return 1
            fi
            sleep $wait_interval
            elapsed_time=$((elapsed_time + wait_interval))
        done
        logit "DEBUG" "stop_world: process exit wait = $elapsed_time seconds."
    fi

    # Provide feedback about screen termination
    logit "INFO" "stop_world: World '$WORLD_NAME' has been stopped cleanly."
    if [ "$silent_mode" != "silent" ]; then
        echo "World '$WORLD_NAME' has been stopped cleanly. It will restart on schedule if autorestart is still set."
        echo "Use './sapiens.sh hardstop' to stop the server and cancel the autorestart schedule."
    fi

    return 0
}

#Stop the server, and cancel the restart timer
hardstop_world() {
    if stop_world; then
        logit "INFO" "hardstop_world: '$WORLD_NAME' has been hard stopped."
        echo "'$WORLD_NAME' has been hard stopped."
    else
        logit "ERROR" "hardstop_world: Failed to stop '$WORLD_NAME'."
        echo "Failed to stop '$WORLD_NAME'."
    fi
    auto_restart "0"
}

# Function to backup the world folder to the specified backup directory.
backup_world() {
    echo -e "${CYAN}Stopping server if necessary...${NC}"
    logit "DEBUG" "backup_world: Calling stop_world silently"
    stop_world "silent"

    echo -e "Backing up the world ${BRIGHT_GREEN}'$WORLD_NAME'${NC}..."
    logit "INFO" "Backing up the world '$WORLD_NAME'"
    local TIMESTAMP=$(date +%Y%m%d%H%M%S)
    local BACKUP_FILE="sapiens_backup_$TIMESTAMP.tar.gz"
    local PARENT_DIR="${WORLD_DIR%/*}"
    
    cd "$PARENT_DIR" || { logit "ERROR" "Failed to change directory to $PARENT_DIR"; echo "Failed to change directory to $PARENT_DIR"; exit 1; }
    
    # Perform the backup and check for errors
    if tar -czf "$WORLD_BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"; then
        echo -e "${GREEN}Backup complete!${NC}"
        logit "INFO" "backup_world: Backup successfully completed."
    else
        echo -e "${RED}Backup process failed!${NC}" >&2
        logit "ERROR" "backup_world: Backup failed."
        exit 1
    fi
}

# Open the screen session to see the server console
open_console() {
    # Call world_status to see if the screen session exists
    if world_status; then
        # If a screen session is found, resume it
        echo ""
        echo -e "${CYAN}You are about to enter the ${GREEN}Sapiens Server Console.${NC}"
        echo -e "${YELLOW}To exit out of the console to the command prompt without stopping your world:${NC}"
        echo ""
        echo -e "${YELLOW}Hold ${BRIGHT_CYAN}${BOLD}CTRL${NC}${YELLOW} and then press ${BRIGHT_CYAN}${BOLD}A${NC} ${YELLOW}and ${BRIGHT_CYAN}${BOLD}D${NC}${YELLOW}.${NC}"
        echo ""
        echo -e "${GREEN}Press any key to open the console...${NC}"
        # Wait for any key press
        read -n 1 -s
        logit "DEBUG" "open_console: Opening screen session $SCREEN_NAME"
        screen -r $SCREEN_NAME
    else
        # Let the user know.
        logit "WARN" "The console for $WORLD_NAME was not found [screen=$SCREEN_NAME]. Please start the server first." "echo"
    fi
}

# Set a cronjob to restart the Sapiens server at specified hourly intervals or disable the restart.
auto_restart() {
    if [[ "$1" == "0" ]]; then
        # Remove the existing cron job if the interval is set to 0
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/sapiens.sh restart") | crontab -
        logit "INFO" "Auto-restart has been disabled." "echo"
    elif [[ "$1" =~ ^[1-9]$|^1[0-9]$|^2[0-4]$ ]]; then
        INTERVAL="$1"
        CRON_JOB="0 */$INTERVAL * * * $SCRIPT_DIR/sapiens.sh restart"
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/sapiens.sh restart"; echo "$CRON_JOB") | crontab -
        echo "$WORLD_NAME will restart every $INTERVAL hour(s)."
        logit "INFO" "auto_restart: $WORLD_NAME set to restart every $INTERVAL hour(s)."
    else
        logit "ERROR" "Interval must be a number of hours between 1 and 24 or 0 to disable." "echo"
        exit 1
    fi
}

# Send a chat message to the online players in the world.
broadcast_message(){
    local message=$1
    logit "INFO" "broadcast_message: $message"
    screen -S "$SCREEN_NAME" -p 0 -X stuff "server:broadcast('$message')$(printf \\r)" >/dev/null 2>&1
}