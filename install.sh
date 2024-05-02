#!/bin/bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Initial setup of Steamcmd, Sapiens Server, and configuration file.
# TO_DO: Update the script so that it picks up an existing install

# Check if the script is running as root

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

# Let's ask for some stuff.
echo "Sapiens Dedicated Server Linux Install Script"
echo "Author: ChillGenXer (chillgenxer@gmail.com)"
echo "Version: 0.2"
echo "-----------------------------------------------------------------------------------------------------------------"
echo "You are about to install the Sapiens Dedicated Server.  The Sapiens Server requires GLIBC_2.38 or higher."
echo "This script has been tested on Ubuntu 23.10 (22.04 will not work), higher versions should work as well."
echo "Other Linux distributions with the correct GLIBC version should work but have not been tested."
echo ""
echo "Please note this installation script supports 1 server running 1 world, which should be fine for the majority."
echo "If you require something more complicated, a manual install is probably the best route."
echo "-----------------------------------------------------------------------------------------------------------------"
echo ""
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

#This will be the static player name for the server to run on.
SERVER_ID="sapserver"

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

# Check if the user wants to advertise the server.
if ask_yes_no "Advertise Server to the public in-game?"; then
    ADVERTISE="true"
    echo "Server will be advertised."
else
    ADVERTISE="false"
    echo "Server will not be advertised."
fi

# Set default port values
default_udp_port=16161
default_http_port=16168

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

# Read UDP port from user or use default
echo ""
UDP_PORT=$(read_port "Enter UDP Port" $default_udp_port)

# Calculate the Steam port, which is UDP port + 1
STEAM_PORT=$((UDP_PORT + 1))

# Read HTTP port from user or use default
HTTP_PORT=$(read_port "Enter HTTP Port" $default_http_port)

# Ensure the third port does not conflict with the HTTP port
while [ "$STEAM_PORT" -eq "$HTTP_PORT" ]; do
    echo "Conflict detected: HTTP port ($HTTP_PORT) cannot be the same as Steam port ($STEAM_PORT)."
    # Re-prompt for the HTTP port
    HTTP_PORT=$(read_port "Enter a different HTTP Port" $default_http_port)
done

#TODO - (Later) - Ask for world time parameters
#TODO - Externalize as an update script to change installed server config.

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

echo "Running steamcmd and installing Sapiens Dedicated Server...\n\n"
# Run steamcmd with preconfigured Sapiens Server update script
steamcmd +runscript ~/sapiens-server/steamupdate.txt

echo "Patching mislocated steamclient.so...\n"

# Create directory and link libraries
link_path="$HOME/.steam/sdk64/steamclient.so"
target_path="$HOME/.steam/steam/steamcmd/linux64/steamclient.so"

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

# Sapiens should now be installed and ready to run.  Let's create a world.
# TODO - Check that somehow

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

#TODO - Get this updated without a whole Lua install
# Path to the serverConfig.lua file
GAME_CONFIG="$HOME/.local/share/majicjungle/sapiens/serverConfig.lua"

echo "Creating config.sh...\n"
# Check if config.sh exists, if not, create it
CONFIG_FILE="config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    cat <<EOF >"$CONFIG_FILE"
#!/bin/bash

# Variables set up during installation.  You shouldn't touch these at the moment.  An executable config script will come soon.
SERVER_NAME="$SERVER_NAME"
WORLD_NAME="$WORLD_NAME"
SERVER_ID="$SERVER_ID"
WORLD_ID="$WORLD_ID"

# Network settings.  If exposing to the internet you will need to port forward all of these on your router.
UDP_PORT=$UDP_PORT
#STEAM_PORT=$STEAM_PORT - Not configurable, listed for reference.  If you change the UDP_PORT this will be UDP_PORT + 1
HTTP_PORT=$HTTP_PORT

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
fi

# Make necessary scripts executable
chmod +x sapiens.sh start.sh

echo "-----------------------------------------------------------------------------------------------------------------"
echo "Sapiens Dedicated Server Installation complete!"
echo "-----------------------------------------------------------------------------------------------------------------"
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
echo "-----------------------------------------------------------------------------------------------------------------"
