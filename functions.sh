#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file to externalize a few of the functions.

#Inventory for our worlds.
declare -a server_ids
declare -a world_ids
declare -a world_names
declare -a display_lines

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

# This function acts as the entry point and controls the flow of the menu system.
start_application() {
    while true; do
        clear
        main_menu
        case $? in
            1)  # Exit the application
                echo "Closing Sapiens Server manager.  Control your server with the ./sapiens.sh command."
                break
                ;;
            *)  # For all other cases, loop back to the main menu
                ;;
        esac
    done
}

main_menu() {
    local options=(
        "1" "Launch/Reconfigure an Existing World"
        "2" "Create a New World"
        "3" "Update Sapiens Server From Steam"
        "4" "Reinstall Dependencies"
        "5" "Exit"  # Adding an explicit exit option
    )
    
    local user_choice=$(whiptail --title "Sapiens Server Manager" --menu "Choose an option:" 15 60 5 "${options[@]}" 3>&1 1>&2 2>&3)

    case $user_choice in
        1)
            if refresh_worldlist; then
                manage_worlds
            else
                whiptail --msgbox "There are no worlds installed on account $(whoami). Create a new one to get started." 8 70
            fi
            ;;
        2)
            create_world_ui
            ;;
        3)
            upgrade_sapiens
            ;;
        4)
            install_dependencies
            ;;
        5)
            echo "Exiting application."
            return 1  # Exit application
            ;;
        *)
            if [ -z "$user_choice" ]; then
                return 1  # Signal to exit application if user pressed ESC or Cancel
            else
                whiptail --msgbox "Invalid choice. Please try again." 8 45
            fi
            ;;
    esac
    return 0
}

# Function to display and select a world from the list using whiptail
manage_worlds() {
    refresh_worldlist

    # Check the exit status of the last command
    if [ $? -ne 0 ]; then
        whiptail --msgbox "No worlds found installed for $(whoami)." 10 50
        return 1  # Return an error code if refresh_worldlist failed
    fi

    # Prepare a menu using whiptail with available worlds
    local options=()
    local max_length=0
    local line
    local index=1  # Initialize index for options array
    for line in "${display_lines[@]}"; do
        options+=("$index" "$line")
        (( ${#line} > max_length )) && max_length=${#line}
        ((index++))
    done

    # Calculate the appropriate width based on the longest line
    local width=$(( max_length + 10 ))  # Add some padding to the max length
    local height=$(( ${#options[@]} / 2 + 8 ))
    local menu_height=$(( height - 8 ))

    # Check if width is less than minimum width
    if [[ $width -lt 70 ]]; then
        width=70
    fi

    # Display the menu
    local selection=$(whiptail --menu "Choose a world to manage:" $height $width $menu_height "${options[@]}" 3>&1 1>&2 2>&3)

    # Handle the user's selection or cancellation
    if [ $? -eq 0 ] && [ -n "$selection" ]; then
        local actual_index=$((selection))
        SERVER_ID="${server_ids[$actual_index]}"
        WORLD_ID="${world_ids[$actual_index]}"
        WORLD_NAME="${world_names[$actual_index]}"
        echo "Selected World: $WORLD_NAME (Server ID: $SERVER_ID, World ID: $WORLD_ID)"
        return 0  # Valid selection
    else
        whiptail --msgbox "No selection made or cancelled." 10 50
        return 1  # User cancelled or closed the menu
    fi
}

# Function to refresh and check world list
refresh_worldlist() {
    local server_dir world_dir
    local counter=1
    local world_found=false

    for server_dir in "$PLAYERS_DIR"/*; do
        if [ -d "$server_dir/worlds" ]; then
            for world_dir in "$server_dir/worlds"/*; do
                if [ -d "$world_dir" ] && [ -f "$world_dir/info.json" ]; then
                    world_found=true
                    local server_id=$(basename "$server_dir")
                    local world_id=$(basename "$world_dir")
                    local world_name=$(jq -r '.value0.worldName' "$world_dir/info.json")

                    server_ids[counter]=$server_id
                    world_ids[counter]=$world_id
                    world_names[counter]="$world_name"
                    display_lines[counter]="    $counter. World Name: $world_name, World ID: $world_id"

                    ((counter++))
                fi
            done
        fi
    done

    if [ "$world_found" = true ]; then
        return 0  # Success: at least one world found
    else
        return 1  # Error: no worlds found
    fi
}

# Function to center text based on terminal width
print_centered() {
    local input="$1"
    printf "%*s\n" $(( (${#input} + $(tput cols)) / 2 )) "$input"
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

# Function to ask for yes/no response
ask_yes_no() {
    local prompt="$1"
    local input

    while true; do
        # Ask the user and read the input
        read -p "$prompt [y/n]: " input
        
        # Check the response
        case "$input" in
            [Yy]) return 0 ;;  # Return 0 for 'yes' responses
            [Nn]) return 1 ;;  # Return 1 for 'no' responses
            *) echo "Please enter y or n." ;;  # Prompt again for anything else
        esac
    done
}

# Function to read port with default
read_port() {
    local prompt=$1
    local default_port=$2
    local input

    # Prompt the user and read input
    read -p "$prompt [$default_port]: " input

    # Use the default if no input is provided
    echo "${input:-$default_port}"
}

# Add the script directory to the path
add_to_path(){
    # Check if the directory is already in the PATH
    if [[ ":$PATH:" != *":$SCRIPT_DIR:"* ]]; then
        # Adding the directory to PATH in .bashrc
        echo "export PATH=\$PATH:$SCRIPT_DIR" >> $HOME/.bashrc
        echo "$SCRIPT_DIR added to your PATH."
    else
        echo "$SCRIPT_DIR is already in your PATH."
    fi

    # Source the .bashrc to update the PATH in the current session
    source $HOME/.bashrc
}

# Get the details for the world that will be controlled by the scripts.
get_new_server_details() {
    read -p "World Name [Nameless Sapiens World]): " WORLD_NAME
    if [ -z "$WORLD_NAME" ]; then
        WORLD_NAME="Nameless Sapiens World"
    fi
}

# Get the details for advertising the server on the network.
get_multiplayer_details(){
    echo "----------------------------------------------------------------------------------------------"
    echo " If you choose to advertise your server, in the multiplayer server tab it will look like this:"
    echo ""
    echo "      My Server Name - $WORLD_NAME"
    echo ""
    echo "----------------------------------------------------------------------------------------------"
    read -p "Server Name [My Server Name]): " SERVER_NAME
    # Check if we need a default value set.
    if [ -z "$SERVER_NAME" ]; then
        SERVER_NAME="My Server Name"
    fi

    if ask_yes_no "Advertise Server to the public in-game?"; then
        ADVERTISE="true"
        echo "Server will be advertised."
    else
        ADVERTISE="false"
        echo "Server will not be advertised."
    fi

    if ask_yes_no "If you don't mind helping the developer to fix bugs in Sapiens, do you want to send your log files on a crash?"; then
        PROVIDE_LOGS="--yes "
        echo "Log reporting Enabled."
        if ask_yes_no "Do you also want to send a copy of your world (can take long for large worlds)?"; then
            PROVIDE_LOGS="--yes-upload-world "
            echo"Log reporting + world send Enabled."
        fi
    else
        PROVIDE_LOGS=""
        echo "No reports will be sent to the developer on a crash."
    fi

}

# Get the network ports required by the server
get_network_ports(){
    # Read UDP port from user or use default
    echo ""
    UDP_PORT=$(read_port "Enter UDP Port" $UDP_PORT)

    # Calculate the Steam port, which is UDP port + 1
    STEAM_PORT=$((UDP_PORT + 1))

    # Read HTTP port from user or use default
    HTTP_PORT=$(read_port "Enter HTTP Port" $HTTP_PORT)

    # Ensure the Steam port does not conflict with the HTTP port
    while [ "$STEAM_PORT" -eq "$HTTP_PORT" ]; do
        echo "Conflict detected: HTTP port ($HTTP_PORT) cannot be the same as Steam port ($STEAM_PORT)."
        # Re-prompt for the HTTP port
        HTTP_PORT=$(read_port "Enter a different HTTP Port" $HTTP_PORT)
    done
}

#Check if our dependencies are installed and check if sapiens is installed.
get_dependency_status() {
    local dependencies=(screen psmisc steamcmd jq)
    local steamcmd_dir="$HOME/.local/share/Steam/steamcmd" # Base directory for SteamCMD
    local executable_name="linuxServer" # Executable to check for

    SAPIENS_INSTALLED="false" # Default to false until found

    # Check for package dependencies
    for pkg in "${dependencies[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            #echo "DEBUG: Return with error if a dependency is not installed"
            return 1 # Return with error if a dependency is not installed
        fi
    done
    #Check for sapiens. I don't think this is needed
    if find "$steamcmd_dir" -type f -name "$executable_name" 2>/dev/null | grep -q . 2>/dev/null; then
        SAPIENS_INSTALLED="true"
    fi 
}

# Install the required dependencies.
install_dependencies(){
    # Dependency List:
    # -----------------------------------------------------------------------------------
    # screen - Used to virtualize the server so the console doesn't need to remain open.
    # psmisc - killall command.
    # steamcmd - Steam commandline tool for installing the Sapiens server.
    # jq - Allows reading json files.
    # procps - process grep

    echo ""
    echo "Installing dependencies..."
    echo ""

    # Add the Steam repository and prep for install
    sudo add-apt-repository multiverse
    sudo dpkg --add-architecture i386
    sudo apt update

    # Install Steamcmd and other dependencies
    sudo apt install screen psmisc procps steamcmd jq
}

# Uses a steamcmd config file where the sapiens appID is set. Despite the name, this can be used for a fresh install as well.
upgrade_sapiens(){
    echo "Running steamcmd and refreshing Sapiens Dedicated Server..."
    # Run steamcmd with preconfigured Sapiens Server update script
    steamcmd +runscript ~/sapiens-server/steamupdate.txt
}

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

create_world_ui() {
    # Prompt for the world name using whiptail
    WORLD_NAME=$(whiptail --inputbox "Enter the name for the new world (or leave empty for 'Nameless Sapiens World'):" 10 60 3>&1 1>&2 2>&3)
    
    # Default the world name if none is provided
    if [ -z "$WORLD_NAME" ]; then
        WORLD_NAME="Nameless Sapiens World"
    fi

    # Show a gauge while the world is being created
    {
        echo 10
        sleep 1
        $HOME/.local/share/Steam/steamcmd/sapiens/linuxServer --server-id "$SERVER_ID" --new "$WORLD_NAME" >/dev/null 2>&1 &
        pid=$!
        echo 50
        sleep 5  # Simulate some progress
        kill $pid  # Intending to stop the background process as per your original function
        sleep 2
        if kill -0 $pid 2>/dev/null; then
            echo 75
            sleep 1
            echo 100
            whiptail --msgbox "Failed to create world. Please try again." 10 50
            return 1
        fi
        echo 100
    } | whiptail --gauge "Please wait, creating the world..." 6 50 0

    # Attempt to retrieve the WORLD_ID of the new world
    base_dir="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds"
    for world_dir in "$base_dir"/*; do
        info_json="$world_dir/info.json"
        if [[ -f "$info_json" ]]; then
            current_world_name=$(jq -r '.value0.worldName' "$info_json")
            if [[ "$current_world_name" == "$WORLD_NAME" ]]; then
                WORLD_ID=$(basename "$world_dir")
                break
            fi
        fi
    done

    # Validate if WORLD_ID was successfully retrieved
    if [[ -z "$WORLD_ID" ]]; then
        whiptail --msgbox "Failed to find the newly created world. Please verify and configure manually." 10 50
    else
        whiptail --msgbox "$WORLD_NAME creation completed successfully with World ID: $WORLD_ID. You can now configure this world in the main menu." 10 70
    fi
}

# Create a new world on the server.
create_world(){
    # Get the PID of the background process and wait.
    $HOME/.local/share/Steam/steamcmd/sapiens/linuxServer --server-id "$SERVER_ID" --new "$WORLD_NAME" >/dev/null 2>&1 &
    pid=$!
    echo "Please wait, creating Sapien world '$WORLD_NAME' with background process PID $pid..."
    sleep 5

    # Kill the process and wait
    kill $pid
    sleep 2

    # Check if the process was successfully killed
    if kill -0 $pid 2>/dev/null; then
        echo "Failed to kill process $pid, something went wrong."
    else
        echo "World creation complete!"
    fi

    #Let's get the WORLD_ID of the new world.
    # Define the base directory where worlds are stored
    base_dir="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds"

    # Check each subdirectory within the worlds directory
    for world_dir in "$base_dir"/*; do
        # Path to the potential info.json file
        info_json="$world_dir/info.json"

        # Check if the info.json file exists
        if [[ -f "$info_json" ]]; then
            # Extract the worldName from the info.json file
            current_world_name=$(jq -r '.value0.worldName' "$info_json")

            # Compare the extracted world name with the expected world name
            if [[ "$current_world_name" == "$WORLD_NAME" ]]; then
                # If the world name matches, extract and set the WORLD_ID
                WORLD_ID=$(basename "$world_dir")
                break
            fi
        fi
    done

    # Check if WORLD_ID was set
    if [[ -z "$WORLD_ID" ]]; then
        echo "No matching world found for world name $WORLD_NAME.  Something has gone wrong, please update World ID manually in config.sh."
    else
        echo "World ID for '$WORLD_NAME' is '$WORLD_ID'."
    fi
}

# Final summary of what was done.
install_summary(){
    #Get IP Address
    IP_ADDRESS=$(ip addr show $(ip route show default | awk '/default/ {print $5}') | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')

    echo "---------------------------------------------------------------------"
    echo "          Sapiens Dedicated Server Installation complete!"
    echo ""
    echo "Summary:"
    echo ""
    echo "Server Name: $SERVER_NAME"
    echo "World Name: $WORLD_NAME"
    echo "Local IP Address: $IP_ADDRESS"
    echo "UDP Port: $UDP_PORT"
    echo "Steam Port (UDP Port + 1): $STEAM_PORT"    
    echo "HTTP Port: $HTTP_PORT"
    echo "Server Publicly Advertised: $ADVERTISE"
    echo "Multiplayer Server Entry: $SERVER_NAME - $WORLD_NAME"
    echo "---------------------------------------------------------------------"
    echo "If you intend to expose the server outside your network please ensure"
    echo "you forward these ports on your router to this machine (IP Address $IP_ADDRESS)."
    echo ""
    echo "You can now control this world with the './sapiens.sh' command. Type"
    echo "it to see options."
}

# Sets permissions so the management scripts can run.
set_permissions(){
    # Make necessary scripts executable
    chmod +x sapiens.sh start.sh backuplogs.sh
}

create_config() {

    # Delete the existing config file if it exists
    [ -f "$CONFIG_FILE" ] && rm "$CONFIG_FILE"

    # Create a new config file
    cat <<EOF >"$CONFIG_FILE"
#!/usr/bin/env bash

#---------------------------------------------------------------------------------------------
# WARNING! This file is regenerated by the install script to support the other scripts
# so you shouldn't change the values in here. Please run ./install.sh if you want to 
# change these values, select your existing world when found and fill in the values to change.
#---------------------------------------------------------------------------------------------

VERSION="0.4.1" # Revision number of the script set

# Variables set up during installation.  
SCRIPT_DIR="$SCRIPT_DIR"        # Base dir where the scripts are located.
WORLD_NAME="$WORLD_NAME"        # The name of the world that people will see in-game
SERVER_ID="$SERVER_ID"          # The server dir name in the "players" dir
WORLD_ID="$WORLD_ID"            # The unique world id that was generated
SCREEN_NAME="sapiens-server"    # Screen name for the server session.

# Network settings.  If exposing to the internet you will need to port forward all of these on your router.
UDP_PORT="$UDP_PORT"
#STEAM_PORT="$STEAM_PORT" - Not configurable, listed for reference.  If you change the UDP_PORT this will be UDP_PORT + 1
HTTP_PORT="$HTTP_PORT"
ADVERTISE=$ADVERTISE
SERVER_NAME="$SERVER_NAME"      # Name of the server, as shown in Multiplayer Tab
PROVIDE_LOGS="$PROVIDE_LOGS"

# Server locations
GAME_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"        # Where Steam installs the linuxServer executable
SAPIENS_DIR="$HOME/.local/share/majicjungle/sapiens"        # Location where linuxServer stores data
BACKUP_DIR="$HOME/sapiens-server/world_backups"             # Folder where the backup command will send your world archive

# World Locations
WORLD_DIR="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID"
WORLD_CONFIG_LUA="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/config.lua"
WORLD_INFO="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/info.json"

# Logging
LOG_BACKUP_DIR="$HOME/sapiens-server/log_backups"           # Folder where the logs will be archived.
ENET_LOG="$SAPIENS_DIR/enetServerLog.log"
SERVERLOG_LOG="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/logs/serverLog.log"
WORLD_LOGS_DIR="$HOME/.local/share/majicjungle/sapiens/players/$SERVER_ID/worlds/$WORLD_ID/logs"
EOF
}
