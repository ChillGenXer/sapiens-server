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

world_status() {
    # Checks to see if there is an active screen session, implying the server is up
    #TODO Should probably check for the linuxServer process too to make this more robust

    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
    local status=$?  # Capture the exit code of the grep command

    # Log the status before exiting the function
    if [ $status -eq 0 ]; then
        logit "INFO" "world_status is reporting a screen session $SCREEN_NAME found, so server is probably running."
    else
        logit "WARN" "world_status was unable to find a screen session named $SCREEN_NAME, server is probably not running."
    fi

    return $status  # Explicitly return the captured exit code
}

# Starts the dedicated server in a screen session
start_world() {
    world_status
    if [ $? -eq 0 ]; then
        read -p "$(echo -e "${CYAN}It appears there is already a Sapiens server running. Do you want to open the server console instead? (${GREEN}y${YELLOW}/${RED}n${YELLOW}): ${NC}")" choice
        case $choice in
            y|Y)
                logit "INFO" "Running open_console"
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
        logit "INFO" "Sapiens world '$WORLD_NAME' started in the background. View the console with ./sapiens.sh console." "echo"
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

    if [ "$silent_mode" != "silent" ]; then
        logit "INFO" "Silently shutting down $WORLD_NAME..."
    fi

    # Loop to check if the screen session is still running
    while screen -list | grep -q "$SCREEN_NAME"; do
        if [ $elapsed_time -ge $max_wait_time ]; then
            logit "WARN" "Screen session $SCREEN_NAME did not stop within $max_wait_time seconds. Proceeding to forcefully kill linuxServer process."
            break
        fi
        sleep $wait_interval
        elapsed_time=$((elapsed_time + wait_interval))
    done

    # If screen session is still running, forcefully kill the linuxServer process
    if screen -list | grep -q "$SCREEN_NAME"; then
        killall "linuxServer"
        logit "INFO" "Forcefully killed linuxServer process."

        elapsed_time=0
        # Loop to check if the linuxServer process is still running
        while pgrep -x "linuxServer" > /dev/null; do
            if [ $elapsed_time -ge $max_wait_time ]; then
                logit "ERROR" "linuxServer process did not terminate within $max_wait_time seconds after killall command."
                return 1
            fi
            sleep $wait_interval
            elapsed_time=$((elapsed_time + wait_interval))
        done
    fi

    # Provide feedback about screen termination
    if [ "$silent_mode" != "silent" ]; then
        logit "INFO" "World '$WORLD_NAME' has been stopped."
    fi

    return 0
}

#Stop the server, and cancel the restart timer
hardstop_world(){
    if pgrep -x "linuxServer" > /dev/null; then
        killall linuxServer
    fi
    logit "INFO" "'$WORLD_NAME' has been hard stopped." "echo"
    auto_restart "0"
}

# Function to backup the world folder to the specified backup directory.
backup_world() {
    echo -e "${CYAN}Stopping server if necessary...${NC}"
    stop_world "silent"

    echo -e "Backing up the world ${BRIGHT_GREEN}'$WORLD_NAME'${NC}..."
    local TIMESTAMP=$(date +%Y%m%d%H%M%S)
    local BACKUP_FILE="sapiens_backup_$TIMESTAMP.tar.gz"
    local PARENT_DIR="${WORLD_DIR%/*}"
    
    cd "$PARENT_DIR" || { echo -e "${RED}Failed to change directory to $PARENT_DIR${NC}"; exit 1; }
    
    # Perform the backup and check for errors
    if tar -czf "$WORLD_BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"; then
        echo -e "${GREEN}Backup complete!${NC}"
    else
        echo -e "${RED}Backup process failed!${NC}" >&2
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

# Send a chat message to the online players in the world.
broadcast_message(){
    local message=$1
    screen -S "$SCREEN_NAME" -p 0 -X stuff "server:broadcast('$message')$(printf \\r)" >/dev/null 2>&1
}