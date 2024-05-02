#!/bin/bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file to externalize a few of the functions.

# This function checks to make sure that the user is not using "root" to install the server.
check_for_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "The Sapiens Server should not be run as the root user. Please create a new user to run the server that has sudo access."
        echo "The user 'sapserver' is used in the instructions, you can create it like this logged in as root (as you are now):"
        echo ""
        echo "  adduser sapserver"
        echo "  usermod -aG sudo sapserver"
        echo ""
        echo "Once this user has been created log in as that user, get this project and run this script again."
        exit 1
    fi
}

# Function to perform world selection
select_world() {

    declare -a server_ids
    declare -a world_ids
    declare -a world_names
    declare -a display_lines

    counter=1
    world_found=false

    # Search through each server directory to check for worlds
    for server_dir in "$PLAYERS_DIR"/*; do
        if [ -d "$server_dir/worlds" ]; then
            for world_dir in "$server_dir/worlds"/*; do
                if [ -d "$world_dir" ] && [ -f "$world_dir/info.json" ]; then
                    world_found=true
                    break 2  # Exit both loops if at least one world is found
                fi
            done
        fi
    done

    if [ "$world_found" = true ]; then
        echo ""
        echo "Existing worlds found. If you would like to use an existing world, select its number."
        echo "Otherwise to create a new world select '0'."
        echo ""
        for server_dir in "$PLAYERS_DIR"/*; do
            if [ -d "$server_dir/worlds" ]; then
                server_id=$(basename "$server_dir")
                echo "Server ID: $server_id"
                for world_dir in "$server_dir/worlds"/*; do
                    if [ -f "$world_dir/info.json" ]; then
                        world_id=$(basename "$world_dir")
                        world_name=$(jq -r '.value0.worldName' "$world_dir/info.json")
                        server_ids[counter]=$server_id
                        world_ids[counter]=$world_id
                        world_names[counter]="$world_name"
                        display_lines[counter]="    $counter. World Name: $world_name, World ID: $world_id"
                        echo "${display_lines[counter]}"
                        ((counter++))
                    fi
                done
            fi
        done

        while true; do
            echo ""
            echo "Enter the number corresponding to the world you want, or '0' to create a new one:"
            read selection

            if [[ $selection -eq 0 ]]; then
                return 1
            elif [[ $selection -ge 1 && $selection -lt $counter ]]; then
                SERVER_ID="${server_ids[$selection]}"
                WORLD_ID="${world_ids[$selection]}"
                WORLD_NAME="${world_names[$selection]}"
                return 0
            else
                echo "Invalid selection. Please try again."
            fi
        done
    else
        echo "No existing worlds found, initiating fresh install."
        return 1
    fi
}

# Welcome screen
splash_text() {
    echo "Sapiens Dedicated Server Linux Install Script"
    echo "Author: ChillGenXer (chillgenxer@gmail.com)"
    echo "Version: $VERSION"
    echo "-------------------------------------------------------------------------------------------------------------"
    echo "You are about to install the Sapiens Dedicated Server.  The Sapiens Server requires GLIBC_2.38 or higher."
    echo "This script has been tested on Ubuntu 23.10 (22.04 will not work), higher versions should work as well."
    echo "Other Linux distributions with the correct GLIBC version should work but have not been tested."
    echo ""
    echo "Please note this installation script supports 1 server running 1 world, which should be fine for the majority."
    echo "If you require something more complicated, a manual install is probably the best route."
    echo "-------------------------------------------------------------------------------------------------------------"
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

# Function to decide on advertising the server
get_new_server_details() {

    echo "If you choose to advertise your server, in the multiplayer server tab it will look like this:"
    echo ""
    echo "      My Server Name - My World Name"
    echo ""
    echo "The World Name is also shown in-game when you bring up the map.  This is what people will know it by the most."
    echo "Even if you don't intend to advertise your server as public, these need to be set."
    echo ""
    read -p "Server Name [My Server]): " SERVER_NAME
    read -p "World Name [Nameless Sapiens World]): " WORLD_NAME

    # Check if we need a default value set.
    if [ -z "$SERVER_NAME" ]; then
        SERVER_NAME="My Server"
    fi
    if [ -z "$WORLD_NAME" ]; then
        WORLD_NAME="Nameless Sapiens World"
    fi

    if ask_yes_no "Advertise Server to the public in-game?"; then
        ADVERTISE="true"
        echo "Server will be advertised."
    else
        ADVERTISE="false"
        echo "Server will not be advertised."
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

# Install the required dependencies.  This should be idempotent, I think.
install_dependencies(){
    # Dependency List:
    # -----------------------------------------------------------------------------------
    # screen - Used to virtualize the server so the console doesn't need to remain open.
    # psmisc - killall command.
    # steamcmd - Steam commandline tool for installing the Sapiens server.
    # jq - Allows reading json files.

    echo ""
    echo "Installing dependencies..."
    echo ""

    # Add the multiverse repository
    sudo add-apt-repository multiverse

    # Add i386 architecture
    sudo dpkg --add-architecture i386

    # Update package lists
    sudo apt update

    # Install Steamcmd and other dependencies
    sudo apt install screen psmisc steamcmd jq

}

# Despite the name, this can be used for a fresh install as well.  Uses a steamcmd config file where the sapiens appID is set.
upgrade_sapiens(){
    echo "Running steamcmd and installing Sapiens Dedicated Server...\n\n"
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

# Create a sapiens world.
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
    echo ""
    echo "Sapiens Dedicated Server Installation complete!"
    echo ""
    # Output the selected ports
    echo ""
    echo "Configured Ports:"
    echo "----------------------------------------"
    echo "UDP Port: $UDP_PORT"
    echo "HTTP Port: $HTTP_PORT"
    echo "Steam Port (UDP Port + 1): $STEAM_PORT"

    IP_ADDRESS=$(ip addr show $(ip route show default | awk '/default/ {print $5}') | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
    echo ""
    echo "If you intend to expose the server outside your network please ensure"
    echo "you forward these ports on your router to this machine (IP Address $IP_ADDRESS)"
    echo ""
    echo "type './sapiens.sh' to see the list of commands."
}

set_permissions(){
    # Make necessary scripts executable
    chmod +x sapiens.sh start.sh
}

create_config() {

    # Delete the existing config file if it exists
    [ -f "$CONFIG_FILE" ] && rm "$CONFIG_FILE"

    # Create a new config file
    cat <<EOF >"$CONFIG_FILE"
#!/bin/bash

# Variables set up during installation.  This file is regenerated by the install script so you shouldn't change values in here.
SERVER_NAME="$SERVER_NAME"
WORLD_NAME="$WORLD_NAME"
SERVER_ID="$SERVER_ID"
WORLD_ID="$WORLD_ID"

# Network settings.  If exposing to the internet you will need to port forward all of these on your router.
UDP_PORT="$UDP_PORT"
#STEAM_PORT="$STEAM_PORT" - Not configurable, listed for reference.  If you change the UDP_PORT this will be UDP_PORT + 1
HTTP_PORT="$HTTP_PORT"

# Location of the server executable
GAME_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"

# Location where Sapiens stores data
SAPIENS_DIR="$HOME/.local/share/majicjungle/sapiens"

# Folder where the backup command will send your world archive
BACKUP_DIR="$HOME/sapiens-server/world_backups"

# Folder where the logs will be archived when you stop the server.
LOG_BACKUP_DIR="$HOME/sapiens-server/log_backups"

# Screen name for the server session.  Best to leave this as is.
SCREEN_NAME="sapiens-server"
EOF
}

