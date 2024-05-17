#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup and system functions.

# Determine the name of the current or calling script
current_script=$(basename "${BASH_SOURCE[0]}")
caller_script=$(basename "${BASH_SOURCE[1]}")

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    exit 1
fi

#Getting relevant IP addresses
IP_ADDRESS=$(ip addr show $(ip route show default | awk '/default/ {print $5}') | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
PUBLIC_IP_ADDRESS=$(curl -s https://api.ipify.org)
if [[ $? -ne 0 || -z "$PUBLIC_IP_ADDRESS" ]]; then
    PUBLIC_IP_ADDRESS="UNKNOWN"
fi

# Ensure we have the necessary directories and log files
mkdir -p "$LOG_DIR"
mkdir -p "$LOG_BACKUP_DIR"
mkdir -p "$WORLD_BACKUP_DIR"

# Set the log file name based on the caller script
timestamp=$(date +'%m-%d-%y-%H:%M:%S')
if [[ "$caller_script" == "sapiens.sh" ]]; then
    SAPSERVER_LOG="$LOG_DIR/sapiens_$timestamp.log"
elif [[ "$caller_script" == "startserver.sh" ]]; then
    SAPSERVER_LOG="$LOG_DIR/startserver_$timestamp.log"
else
    SAPSERVER_LOG="$LOG_DIR/sapiens_$timestamp.log"
fi

# Ensure the log file is created
touch "$SAPSERVER_LOG"

# Welcome screen
splash_text() {
    local width=$(tput cols)  # Get the current width of the terminal
    local line=$(printf '%*s' "$width" | tr ' ' '-')  # Create a separator line of the appropriate length

    local title="$SCRIPT_NAME"
    local author="Author: ChillGenXer (chillgenxer@gmail.com)"
    local version="Version: $SCRIPT_VERSION"
    local tested="This script has been tested on Ubuntu 23.10 (22.04 will not work), higher versions should work as well."
    local glibc_info="The Sapiens Server requires GLIBC_2.38 or higher. Other Linux distributions with the correct GLIBC version should work but have not been tested."
    local note="Please note this installation script supports 1 server running 1 world, which should be fine for most people. Running multiple servers is planned for a future version."

    clear
    echo "$line"
    printf "%*s\n" $(( (width + ${#title}) / 2 )) "$title"
    printf "%*s\n" $(( (width + ${#author}) / 2 )) "$author"
    printf "%*s\n" $(( (width + ${#version}) / 2 )) "$version"
    echo "$line"
    echo "$tested" | fmt -w "$width"
    echo "$glibc_info" | fmt -w "$width"
    echo ""
    echo "$note" | fmt -w "$width"
    echo "$line"
    echo ""
}

# Runs on exit
shutdown_sequence() {
    logit "DEBUG" "shutdown_sequence initiated."
    
    echo "Sapiens Linux Server Helper Scripts Version $SCRIPT_VERSION" 
    echo "Installation Script install.sh exited."
    echo "Thanks for using these scripts.  If you encounter any issues"
    echo "please raise them at $GITHUB_URL/issues."
}

# A little generic yes/no prompt.
yesno() {
    local prompt="$1"
    local answer
    logit "DEBUG" "yesno() invoked with prompt: '$prompt'"

    # Loop until a valid response is received
    while true; do
        read -p "$prompt (y/n): " answer
        case "$answer" in
            [Yy]) return 0 ;;  # User responded 'yes'
            [Nn]) return 1 ;;  # User responded 'no'
            *) echo "Please answer y or n." ;;  # Invalid response
        esac
    done
}

# Logging function.
logit() {
    # Logs messages with a timestamp and severity to a specified log file and optionally to the console.
    # Skips DEBUG messages if debug_mode is set to "off".
    # Parameters:
    #   $1 - severity (e.g., DEBUG, INFO, WARN, ERROR)
    #   $2 - message (log message string)
    #   $3 - echo flag (optional, 'echo' to print to console)
    # Usage:
    #   logit "ERROR" "Failed to start the server"
    #   logit "INFO" "Server started successfully" "echo"

    local severity="$1"
    local message="$2"
    local echo_flag="${3:-}"  # Optional third parameter, defaults to empty if not provided
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")  # Formats timestamp as 'Year-Month-Day Hour:Minute:Second'
    local valid_severities=("DEBUG" "INFO" "WARN" "ERROR")
    
    # Check if the log file variable is set
    if [ -z "$SAPSERVER_LOG" ]; then
        echo "Error: SAPSERVER_LOG is not set."
        exit 1
    fi

    # Check if the severity is valid
    local is_valid_severity=false
    for valid_severity in "${valid_severities[@]}"; do
        if [[ "$severity" == "$valid_severity" ]]; then
            is_valid_severity=true
            break
        fi
    done

    if [ "$is_valid_severity" = false ]; then
        echo "Invalid severity level: $severity"
        exit 1
    fi

    # Check if debugging is off and severity is DEBUG, then skip logging.  Set in constants.sh.
    if [[ "$DEBUG_MODE" == "off" && "$severity" == "DEBUG" ]]; then
        return 0
    fi

    # Append the log entry to the file
    echo "$timestamp [$severity]: $message" >> "$SAPSERVER_LOG"

    # Check if echo to console is requested
    if [ "$echo_flag" = "echo" ]; then
        echo "$timestamp [$severity]: $message"
    fi
}

#Generate a configuration file
create_config() {
    local config_content
    
    # Assemble the configuration file contents
    logit "DEBUG" "create_config initiated."
    config_content+="#!/usr/bin/env bash\n\n"
    config_content+="# ------------------------------------------------------------------------------\n"
    config_content+="# WARNING! This file is regenerated by the ./install.sh script. You should not \n"
    config_content+="# manually edit the values in this file, they will be overwritten. To change \n"
    config_content+="# configuration settings, please run install.sh.\n"
    config_content+="# ------------------------------------------------------------------------------\n\n"

    config_content+="# Active Server World command line startup args\n"
    config_content+="WORLD_NAME=\"$WORLD_NAME\"\n"
    config_content+="WORLD_ID=\"$WORLD_ID\"\n"
    config_content+="SERVER_ID=\"$SERVER_ID\"\n"
    config_content+="UDP_PORT=\"$UDP_PORT\"\n"
    config_content+="HTTP_PORT=\"$HTTP_PORT\"\n"
    config_content+="ADVERTISE=\"$ADVERTISE\"\n"
    config_content+="PROVIDE_LOGS=\"$PROVIDE_LOGS\"\n\n"

    config_content+="# World Locations\n"
    config_content+="WORLD_DIR=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID\"\n"
    config_content+="WORLD_RUNNING_FILE=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/serverRunning.txt\"\n"
    config_content+="WORLD_CONFIG_LUA=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/config.lua\"\n"
    config_content+="WORLD_INFO=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/info.json\"\n"
    config_content+="ENET_LOG=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/enetServerLog.log\"\n"
    config_content+="SERVERLOG_LOG=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/logs/serverLog.log\"\n"
    config_content+="WORLD_LOGS_DIR=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/logs\"\n"

    # Write the content of the variable to the config file
    logit "DEBUG" "$config_content"
    logit "INFO" "Writing the new configfile to $CONFIG_FILE"
    echo -e "$config_content" > "$CONFIG_FILE"

    # Check for errors in creating the file
    if [ $? -ne 0 ]; then
        logit "INFO" "Failed to create configuration file at $CONFIG_FILE"
        echo "Failed to create configuration file at $CONFIG_FILE"
        exit 1
    fi
}
