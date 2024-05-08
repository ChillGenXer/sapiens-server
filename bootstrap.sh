#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup and system functions.

#Initial settings
CONFIG_FILE="config.sh"
VERSION="0.5.0"

# Array of dependencies for the server to run and needed by the script to work.  It is in an array for clarity
# with the cell name being the actual package name for use in apt package manager, while the value is the command
# used to check if the package is present.
declare -A DEPENDENCIES=(
    [screen]=screen         # Used to virtualize the server so the console doesn't need to remain open.
    [psmisc]=killall        # Needed for the killall command
    [steamcmd]=steamcmd     # Steam commandline tool for installing and updating the Sapiens server.
    [jq]=jq                 # Used for managing json files.
    [procps]=ps             # process grep
    [dialog]=dialog         # Console UI functions
)

# Set a trap to clear the screen when exiting
#trap shutdown_sequence EXIT

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

    # Check if all required dependencies are installed
    if ! get_dependency_status; then
        echo "The account $(whoami) does not have the necessary software installed to run a Sapiens Server. Beginning installation..."

        install_dependencies    # Install Steamcmd and the other required dependencies
        patch_steam             # Patch for the steam client.
        upgrade_sapiens         # Use steamcmd to update the sapiens executable.

        dialog --msgbox "Sapiens Server Manager installation successfully complete!" 0 0
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
    local width=$(tput cols)  # Get the current width of the terminal
    local line=$(printf '%*s' "$width" | tr ' ' '-')  # Create a separator line of the appropriate length

    local title="Sapiens Linux Dedicated Server Install Script"
    local author="Author: ChillGenXer (chillgenxer@gmail.com)"
    local version="Version: $VERSION"
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

# Add a directory to the path
add_to_path(){
    local path_to_add="$1"

    # Check if the directory is already in the PATH
    if [[ ":$PATH:" != *":$path_to_add:"* ]]; then
        # Adding the directory to PATH in .bashrc
        echo "export PATH=\$PATH:$path_to_add" >> $HOME/.bashrc
        echo "$path_to_add added to your PATH."
    else
        echo "$path_to_add is already in your PATH."
    fi

    # Source the .bashrc to update the PATH in the current session
    source $HOME/.bashrc
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
        if ! command -v "${DEPENDENCIES[$pkg]}"; then
            echo "Missing dependency: $pkg (${DEPENDENCIES[$pkg]})" | tee -a "$log_file"
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
    echo ""

    # Add the Steam repository and prep for install
    sudo add-apt-repository -y multiverse
    sudo dpkg --add-architecture i386
    sudo apt update

    # Convert package-command associative array to a list of packages
    local packages=("${!DEPENDENCIES[@]}") # Extracts the keys (package names) from the associative array

    # Install Steamcmd and other dependencies
    sudo apt install -y "${packages[@]}"
}

# Uses a steamcmd config file where the sapiens appID is set. Despite the name, this can be used for a fresh install as well.
upgrade_sapiens(){
    echo "Running steamcmd and refreshing Sapiens Dedicated Server..."
    # Run steamcmd with preconfigured Sapiens Server update script
    steamcmd +runscript ~/sapiens-server/steamupdate.txt
}

# A little hack to fix the location of the steam client
patch_steam(){
    echo "Patching mislocated steamclient.so..."

    # Create directory and link libraries
    link_path="$HOME/.steam/sdk64/steamclient.so"
    target_path="$HOME/.local/share/Steam/steamcmd/linux64/steamclient.so"

    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$link_path")"

    # Check if the symbolic link already exists
    if [ ! -L "$link_path" ]; then
        # Create the symbolic link if it does not exist
        ln -s "$target_path" "$link_path"
        echo "Patch complete."
    else
        echo "Symbolic link already exists, no need to patch."
    fi
}

# Sets permissions so the management scripts can run.
set_permissions(){
    # Make necessary scripts executable
    chmod +x sapiens.sh start.sh backuplogs.sh
}

#Generate a configuration file
create_config() {

	# Define the configuration template in a variable using a heredoc
	CONFIG_CONTENT=$(cat <<-EOF
		#!/usr/bin/env bash
		
		# ------------------------------------------------------------------------------------------
		# WARNING! This file is regenerated by the Sapiens Server Manager application. You
		# should not manually edit the values in this file. To change configuration settings,
		# please run ./sapiens.sh.
		# ------------------------------------------------------------------------------------------
		
		# Script & Sapiens Version
		VERSION="0.5.0"
		
		# Installation Variables
		SCRIPT_DIR="$SCRIPT_DIR"
		WORLD_NAME="$WORLD_NAME"
		SERVER_ID="$SERVER_ID"
		WORLD_ID="$WORLD_ID"
		SCREEN_NAME="sapiens-server"

		# Network Settings
		UDP_PORT="$UDP_PORT"
		HTTP_PORT="$HTTP_PORT"
		ADVERTISE=$ADVERTISE
		SERVER_NAME="$SERVER_NAME"
		PROVIDE_LOGS="$PROVIDE_LOGS"
		
		# Server and Game Locations
		GAME_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"
		SAPIENS_DIR="$HOME/.local/share/majicjungle/sapiens"
		BACKUP_DIR="$HOME/sapiens-server/world_backups"
		PLAYERS_DIR="$SAPIENS_DIR/players"

        # World Locations
        WORLD_DIR="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID"
        WORLD_CONFIG_LUA="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/config.lua"
        WORLD_INFO="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/info.json"
        GAME_CONFIG="$GAME_CONFIG"

		# Logging Directories
		LOG_BACKUP_DIR="$HOME/sapiens-server/log_backups"
		ENET_LOG="$SAPIENS_DIR/enetServerLog.log"
		SERVERLOG_LOG="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/logs/serverLog.log"
		WORLD_LOGS_DIR="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/logs"
	EOF
	)

	# Write the content of the variable to the config file
	echo "$CONFIG_CONTENT" > "$CONFIG_FILE"

	# Check for errors in creating the file
	if [ $? -ne 0 ]; then
		echo "Failed to create configuration file at $CONFIG_FILE"
		exit 1
	fi
}
