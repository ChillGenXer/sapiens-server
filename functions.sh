#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file to externalize a few of the functions.

# Dependencies for the server to run and script to work
declare -A DEPENDENCIES=(
    [screen]=screen
    [psmisc]=killall
    [steamcmd]=steamcmd
    [jq]=jq
    [procps]=ps
    [dialog]=dialog
)

#Inventory for our worlds.
declare -a server_ids
declare -a world_ids
declare -a world_names
declare -a display_lines

# Application Main Menu
main_menu_ui() {
    # Display the active world if one is selected
    local active_world_msg="Active World: ${WORLD_NAME:-'None Selected'}"

    local options=(
        "1" "Manage Active World"
        "2" "Select the Active World"
        "3" "Create a New World"
        "4" "Update Sapiens Server From Steam"
        "5" "Reinstall Dependencies"
        "6" "Exit"  # Adding an explicit exit option
    )
    
    local user_choice=$(whiptail --title "Sapiens Server Manager - $active_world_msg" --menu "Choose an option:" 20 78 6 "${options[@]}" 3>&1 1>&2 2>&3)

    case $user_choice in
        1)
            manage_world_menu_ui
            ;;
        2)
            if refresh_worldlist; then
                select_world_ui
                setup_server_ui
            else
                whiptail --msgbox "There are no worlds installed on account $(whoami). Create a new one to get started." 8 70
            fi
            ;;
        3)
            create_world_ui
            ;;
        4)
            upgrade_sapiens
            ;;
        5)
            install_dependencies
            ;;
        6)
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

# Menu for managing the active world
manage_world_menu_ui() {
    while true; do
        local options=(
            "1" "Show Active World Info"
            "2" "Start Server"
            "3" "Restart Server"
            "4" "Stop Server"
            "5" "Hard Stop Server"
            "6" "Toggle Auto Restart"
            "7" "Backup Server"
            "8" "Open Console"
            "9" "Exit to Main Menu"
        )
        
        local user_choice=$(whiptail --title "Manage Active World - $WORLD_NAME" --menu "Select an operation for the active world:" 20 78 9 "${options[@]}" 3>&1 1>&2 2>&3)
        
        case $user_choice in
            1)
                active_world_info_ui
                ;;
            2)
                start_server
                ;;
            3)
                restart_server
                ;;
            4)
                stop_server
                ;;
            5)
                hardstop_server
                ;;
            6)
                auto_restart
                ;;
            7)
                backup_server
                ;;
            8)
                open_console
                ;;
            9)
                # Exit to the main menu
                break
                ;;
            *)
                if [ -z "$user_choice" ]; then
                    # If the user pressed ESC or Cancel, exit the loop
                    break
                else
                    whiptail --msgbox "Invalid choice. Please try again." 8 45
                fi
                ;;
        esac
    done
}

# Information on the currently active world.
active_world_info_ui() {
    # Initialize local variables
    local send_logs="No"
    local send_world="No"

    # Determine the values based on PROVIDE_LOGS
    case "$PROVIDE_LOGS" in
        "--yes")
            send_logs="Yes"
            ;;
        "--yes-upload-world")
            send_logs="Yes"
            send_world="Yes"
            ;;
    esac

    # Gather server information
    IP_ADDRESS=$(ip addr show $(ip route show default | awk '/default/ {print $5}') | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
    local server_info="Server Name               : $SERVER_NAME\n"
    server_info+="World Name                : $WORLD_NAME\n"
    server_info+="Local IP Address          : $IP_ADDRESS\n"
    server_info+="UDP Port                  : $UDP_PORT\n"
    server_info+="Steam Port (UDP Port + 1) : $((UDP_PORT + 1))\n"  # Calculate Steam port on the fly
    server_info+="HTTP Port                 : $HTTP_PORT\n"
    server_info+="Advertising In-Game       : $( [ "$ADVERTISE" == "true" ] && echo "Yes" || echo "No")\n"
    server_info+="Send logs on crash        : $send_logs\n"
    server_info+="Send world on crash       : $send_world\n"
    server_info+="Multiplayer Server Entry  : $SERVER_NAME - $WORLD_NAME\n"
    server_info+="---------------------------------------------------------------------\n"
    server_info+="If you intend to expose the server outside your network, please ensure\n"
    server_info+="you forward all 3 ports on your router to this machine (IP Address $IP_ADDRESS)."

    # Display the server information
    whiptail --title "Active World Information" --msgbox "$server_info" 20 78
}

# Function to display and select the active world
select_world_ui() {
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

# Function to configure the active world
setup_server_ui() {
    # Get the server name with a default value, defaulting to the existing SERVER_NAME or a placeholder
    SERVER_NAME=$(whiptail --inputbox "Enter server name:" 10 60 "${SERVER_NAME:-'My Server Name'}" 3>&1 1>&2 2>&3)
    SERVER_NAME=${SERVER_NAME:-"My Server Name"}

    # Ask if the server should be advertised with the default set to the existing value
    if whiptail --yesno "Advertise server to the public in-game? Current setting: $( [ "$ADVERTISE" == "true" ] && echo "Yes" || echo "No")" 10 60; then
        ADVERTISE="true"
    else
        ADVERTISE="false"
    fi

    # Ask if logs should be sent on crash
    if whiptail --yesno "Do you want to send your log files to help fix bugs on a crash?" 10 60; then
        PROVIDE_LOGS="--yes"
        # Ask if world data should also be sent
        if whiptail --yesno "Do you also want to send a copy of your world (can take long for large worlds)?" 10 60; then
            PROVIDE_LOGS="--yes-upload-world"
        fi
    else
        PROVIDE_LOGS=""
    fi

    # Get the UDP port, using the existing UDP_PORT if not provided
    UDP_PORT=$(whiptail --inputbox "Enter UDP Port:" 10 60 "$UDP_PORT" 3>&1 1>&2 2>&3)
    UDP_PORT=${UDP_PORT:-$UDP_PORT}

    # Calculate the Steam port, which is UDP port + 1
    STEAM_PORT=$((UDP_PORT + 1))

    # Get the HTTP port, using the existing HTTP_PORT if not provided, and ensure it does not conflict with the Steam port
    HTTP_PORT=$(whiptail --inputbox "Enter HTTP Port:" 10 60 "$HTTP_PORT" 3>&1 1>&2 2>&3)
    HTTP_PORT=${HTTP_PORT:-$HTTP_PORT}
    while [ "$STEAM_PORT" -eq "$HTTP_PORT" ]; do
        HTTP_PORT=$(whiptail --inputbox "Conflict detected: HTTP port ($HTTP_PORT) cannot be the same as Steam port ($STEAM_PORT). Enter a different HTTP Port:" 10 60 "$HTTP_PORT" 3>&1 1>&2 2>&3)
    done

    # Rewrite the config file
    create_config

    # Display summary of configuration
    active_world_info_ui
}

# Create a new Sapiens world via linuxServer --new
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
        sleep 5  
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
    # Dependency List:
    # -----------------------------------------------------------------------------------
    # screen - Used to virtualize the server so the console doesn't need to remain open.
    # psmisc - killall command.
    # steamcmd - Steam commandline tool for installing the Sapiens server.
    # jq - Allows reading json files.
    # procps - process grep
    # dialog - Console UI

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

# Checks to see if there is an active screen session, implying the server is up
check_screen() {
    # Check if a screen session with the specified name exists
    screen -ls | grep -q "$SCREEN_NAME"
}

create_config() {

    # Delete the existing config file if it exists
    [ -f "$CONFIG_FILE" ] && rm "$CONFIG_FILE"

    # Create a new config file
    cat <<EOF >"$CONFIG_FILE"
#!/usr/bin/env bash

#---------------------------------------------------------------------------------------------
# WARNING! This file is regenerated for the Sapiens Server Manager application. You
# shouldn't change the values in here. Please run ./sapiens.sh if you want to 
# change the configuration of the application.
#---------------------------------------------------------------------------------------------

VERSION="0.5.0" # Revision number of the script set

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
PLAYERS_DIR="$SAPIENS_DIR/players"                          # Location of the players folder where the server files reside

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
