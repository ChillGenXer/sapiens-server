#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup and system functions.

# Set a trap to clear the screen when exiting
trap shutdown_sequence EXIT

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local current_script=$(basename "${BASH_SOURCE[0]}")
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    logit "INFO" "Attempt to run $current_script directly detected.  Please use sapiens.sh for all operations."
    exit 1
fi

# First function that will be run to check if all the bits are here
startup_sequence(){
    
    # Check if the script is running as root
    check_for_root

    # Load the Configuration or set defaults
    if [ ! -f "$CONFIG_FILE" ]; then
        create_config  # Function call to create the configuration file
    else
        source $CONFIG_FILE  # Source the existing configuration
    fi

    # Show the welcome screen
    splash_text

    # Check if all required dependencies are installed
    if ! get_dependency_status; then

        echo "The account $(whoami) does not have the necessary software installed."
        if ! yesno "Would you like to install it now?"; then
            echo "Installation aborted."
            exit 0
        fi

        install_dependencies    # Install Steamcmd and the other required dependencies
        patch_steam             # Patch for the steam client.
        upgrade_sapiens         # Use steamcmd to update the sapiens executable.
        create_config           # Generate a new config to get the version number.
        add_to_path $SCRIPT_DIR # Add the script directory to the path.

        echo "Sapiens Server Manager installation successfully complete!"
        read -n 1 -s -r -p "Press any key to continue"
        echo ""  # Move to the next line after the key press
    fi
}

# Runs on exit
shutdown_sequence() {
    clear
    echo "Sapiens Server Manager Version $VERSION" 
    echo "Thanks for using Sapien Server Manager!  If you encounter any issues"
    echo "please raise them at https://github.com/ChillGenXer/sapiens-server/issues ."
    echo ""

}

# This function checks to make sure that the user is not using "root" to install the server.
check_for_root() {
    if [ "$EUID" -eq 0 ]; then
        logit "ERROR" "root user detected.  Exiting."
        echo "The Sapiens dedicated server should not be run as the root user. Please create a new user to run the server that has sudo access."
        echo "The user 'sapserver' is used in the instructions, you can create it like this logged in as root (as you are now):"
        echo ""
        echo "  adduser sapserver"
        echo "  usermod -aG sudo sapserver"
        echo ""
        echo "Once this user has been created log in as that user, get this project and run this script again."
        echo ""
        echo "git clone https://github.com/ChillGenXer/sapiens-server.git"
        exit 1
    fi
}

# Welcome screen
splash_text() {
    local width=70  # Get the current width of the terminal
    local line=$(printf '%*s' "$width" | tr ' ' '-')  # Create a separator line of the appropriate length
    local title="Sapiens Linux Dedicated Server Install Script"
    local author="Author: ChillGenXer (chillgenxer@gmail.com)"
    local repo="GitHub: https://github.com/ChillGenXer/sapiens-server.git"
    local version="Script Version: $VERSION"
    local tested="This script has been tested on Ubuntu 23.10 (22.04 will not work), higher versions should work as well."
    local glibc_info="The Sapiens Server requires GLIBC_2.38 or higher. Other Linux distributions with the correct GLIBC version should work but have not been tested."
    local note="Please note this installation script supports 1 server running 1 world, which should be fine for most people. Running multiple servers is planned for a future version."

    clear
    echo "$line"
    printf "%*s\n" $(( (width + ${#title}) / 2 )) "$title"
    printf "%*s\n" $(( (width + ${#author}) / 2 )) "$author"
    printf "%*s\n" $(( (width + ${#repo}) / 2 )) "$repo"
    printf "%*s\n" $(( (width + ${#version}) / 2 )) "$version"
    echo "$line"
    echo "$tested" | fmt -w "$width"
    echo "$glibc_info" | fmt -w "$width"
    echo ""
    echo "$note" | fmt -w "$width"
    echo "$line"
    echo ""
}

# Adds the script directory to the path configuration.
add_to_path() {
    local path_to_add="$1"
    local shell_config_file

    # Determine which shell the user is using and select appropriate config file
    case "$SHELL" in
        */bash)
            shell_config_file="$HOME/.bashrc"
            ;;
        */zsh)
            shell_config_file="$HOME/.zshrc"
            ;;
        *)
            echo "Unsupported shell. Please add the directory manually to your shell's config file."
            return 1
            ;;
    esac

    # Check if the directory is already in the PATH
    if [[ ":$PATH:" != *":$path_to_add:"* ]]; then
        # Adding the directory to the PATH in the determined shell config file
        echo "export PATH=\$PATH:$path_to_add" >> "$shell_config_file"
        echo "$path_to_add added to your PATH in $shell_config_file."
        source $shell_config_file       # activate the path changes
    else
        echo "$path_to_add is already in your PATH."
    fi
}

#Check if our dependencies are installed and check if sapiens is installed.
get_dependency_status() {
    local steamcmd_dir="$HOME/.local/share/Steam/steamcmd"
    local executable_name="linuxServer"
    local log_file="$HOME/install.log"

    # Check if log file exists and create it if it does not
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
    else
        : > "$log_file"  # Truncate the existing log file to start fresh
    fi

    SAPIENS_INSTALLED="false"
    # Check for package dependencies by command availability
    for pkg in "${!DEPENDENCIES[@]}"; do
        # Capturing command output and suppressing console output
        if ! command_output=$(command -v "${DEPENDENCIES[$pkg]}" 2>/dev/null); then
            echo "Missing dependency: $pkg (${DEPENDENCIES[$pkg]})" >> "$log_file"
            return 1  # Return with error if a dependency is not installed
        else
            # Log the success of found commands to the log file
            echo "${DEPENDENCIES[$pkg]} found" >> "$log_file"
        fi
    done

    # Check for sapiens executable
    if [ -f "$steamcmd_dir/$executable_name" ]; then
        SAPIENS_INSTALLED="true"
        echo "$executable_name found in $steamcmd_dir" >> "$log_file"
    else
        echo "$executable_name not found in $steamcmd_dir" >> "$log_file"
    fi
}

# Install the required dependencies.
install_dependencies(){
    echo ""
    echo "Installing dependencies..."
    logit "INFO" "Installing dependencies"
    echo ""

    # Add the Steam repository and prep for install
    sudo add-apt-repository -y multiverse
    sudo dpkg --add-architecture i386
    sudo apt update

    # Convert package-command associative array to a list of packages
    
    local packages=("${!DEPENDENCIES[@]}") # Extracts the keys (package names) from the associative array

    # Install Steamcmd and other dependencies
    logit "INFO" "Installing dependencies"
    sudo apt install -y "${packages[@]}"
}

# Uses a steamcmd config file where the sapiens appID is set. Despite the name, this can be used for a fresh install as well.
upgrade_sapiens(){
    echo "Running steamcmd and refreshing Sapiens Dedicated Server..."
    logit "INFO" "Running steamcmd and refreshing Sapiens Dedicated Server"
    # Run steamcmd with preconfigured Sapiens Server update script
    steamcmd +runscript ~/sapiens-server/steamupdate.txt
}

# Gets the current version of the Sapiens linuxServer executable
get_sapiens_version() {
    #Run the --help command on the server executable and cut out the version number
    local version_line=$($GAME_DIR/linuxServer --help | grep 'Version:')
    SAPIENS_VERSION=$(echo "$version_line" | cut -d':' -f2 | xargs)
    logit "INFO" "Sapiens linuxServer version $SAPIENS_VERSION"
}

# A little hack to fix the location of the steam client
patch_steam(){
    echo "Patching mislocated steamclient.so..."
    logit "DEBUG" "Patching mislocated steamclient.so"

    # Create directory and link libraries
    link_path="$HOME/.steam/sdk64/steamclient.so"
    target_path="$HOME/.local/share/Steam/steamcmd/linux64/steamclient.so"

    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$link_path")"
    logit "DEBUG" "patch_steam.mkdir dirname $link_path"

    # Check if the symbolic link already exists
    if [ ! -L "$link_path" ]; then
        # Create the symbolic link if it does not exist
        ln -s "$target_path" "$link_path"
        echo "Steam client patch complete."
        logit "DEBUG" "Steam client patch complete."

    else
        echo "Symbolic link already exists, no need to patch."
        logit "DEBUG" "Symbolic link already exists, no need to patch."
    fi
}

# Sets permissions so the management scripts can run.
set_permissions(){
    # Make necessary scripts executable
    logit "DEBUG" "set_permissions() invoked"
    chmod +x sapiens.sh start.sh backuplogs.sh
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
    # Logs messages with a timestamp and severity to a specified log file.
    # Skips DEBUG messages if debug_mode is set to "off".
    # Parameters:
    #   $1 - severity (e.g., DEBUG, INFO, WARN, ERROR)
    #   $2 - message (log message string)
    # Usage:
    #   logit "ERROR" "Failed to start the server"

    local debug_mode="on"  # Set to "on" to enable debug logging, "off" to disable.
    
    local severity="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")  # Formats timestamp as 'Year-Month-Day Hour:Minute:Second'
    local valid_severities=("DEBUG" "INFO" "WARN" "ERROR")
    

    # Check if the log file variable is set
    if [ -z "$SAPSERVER_LOG" ]; then
        echo "Error: SAPSERVER_LOG is not set."
        exit 1
    fi

    # Check if the log file exists and create it if it does not
    if [ ! -f "$SAPSERVER_LOG" ]; then
        touch "$SAPSERVER_LOG"
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

    # Check if debugging is off and severity is DEBUG, then skip logging
    if [[ "$debug_mode" == "off" && "$severity" == "DEBUG" ]]; then
        return 0
    fi

    # Append the log entry to the file
    echo "$timestamp [$severity]: $message" >> "$SAPSERVER_LOG"
}

#Generate a configuration file
create_config() {
    logit "DEBUG" "create_config initiated."
    # Refresh the Sapiens Version
    get_sapiens_version

    # Assemble the configuration file contents
    local config_content
    config_content+="#!/usr/bin/env bash\n\n"
    config_content+="# --------------------------------------------------------------------------------------\n"
    config_content+="# WARNING! This file is regenerated by the Sapiens Server Manager application. You\n"
    config_content+="# should not manually edit the values in this file, they will be overwritten. To change \n"
    config_content+="# configuration settings, please run sapiens.sh.\n"
    config_content+="# --------------------------------------------------------------------------------------\n\n"
    
    config_content+="# Script & Sapiens Version\n"
    config_content+="VERSION=\"0.5.0\"\n"
    config_content+="SAPIENS_VERSION=\"$SAPIENS_VERSION\"\n\n"

    config_content+="# Active Server World command line startup args\n"
    config_content+="WORLD_NAME=\"$WORLD_NAME\"\n"
    config_content+="WORLD_ID=\"$WORLD_ID\"\n"
    config_content+="UDP_PORT=\"$UDP_PORT\"\n"
    config_content+="HTTP_PORT=\"$HTTP_PORT\"\n"
    config_content+="ADVERTISE=\"$ADVERTISE\"\n"
    config_content+="PROVIDE_LOGS=\"$PROVIDE_LOGS\"\n\n"

    config_content+="# Values needed by start.sh\n"
    config_content+="SCRIPT_DIR=\"$SCRIPT_DIR\"\n"
    config_content+="GAME_DIR=\"$GAME_DIR\"\n"
    config_content+="SERVER_ID=\"$SERVER_ID\"\n\n"

    config_content+="# World Locations\n"
    config_content+="WORLD_DIR=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID\"\n"
    config_content+="WORLD_CONFIG_LUA=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/config.lua\"\n"
    config_content+="WORLD_INFO=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/info.json\"\n\n"

    config_content+="# World Logs\n"
    config_content+="ENET_LOG=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/enetServerLog.log\"\n"
    config_content+="SERVERLOG_LOG=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/logs/serverLog.log\"\n"
    config_content+="WORLD_LOGS_DIR=\"$PLAYERS_DIR/$SERVER_ID/worlds/$WORLD_ID/logs\"\n"
    config_content+="LOG_BACKUP_DIR=\"$LOG_BACKUP_DIR\"\n"

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


