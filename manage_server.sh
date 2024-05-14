#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: This script library is used to manage the software-level server.

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    current_script=$(basename "${BASH_SOURCE[0]}")
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    logit "INFO" "Attempt to run $current_script directly detected.  Please use sapiens.sh for all operations."
    exit 1
fi

# Array of dependencies for the server to run and needed by the script to work.  It is in an array for clarity
# with the cell name being the actual package name for use in apt package manager, while the value is the command
# used to check if the package is present.
declare -A DEPENDENCIES=(
    [screen]=screen         # Used to virtualize the server so the console doesn't need to remain open.
    [psmisc]=killall        # Needed for the killall command
    [steamcmd]=steamcmd     # Steam commandline tool for installing and updating the Sapiens server.
    [jq]=jq                 # Used for managing json files.
    [procps]=ps             # process grep
    [sqlite3]=sqlite3       # The configuration database
)

# Gets a list of the worlds installed in the Sapiens data directory
show_installed_worlds() {
    local show_format=$1
    local server_dir world_dir
    local counter=1  # Counter to number each world

    logit "DEBUG" "show_installed_worlds started using PLAYERS_DIR = '$PLAYERS_DIR'"
    for server_dir in "$PLAYERS_DIR"/*; do
        if [ -d "$server_dir/worlds" ]; then
            for world_dir in "$server_dir/worlds"/*; do
                if [ -d "$world_dir" ] && [ -f "$world_dir/info.json" ]; then
                    local server_id=$(basename "$server_dir")
                    local world_id=$(basename "$world_dir")
                    local world_name=$(jq -r '.value0.worldName' "$world_dir/info.json")
                    
                    if [[ "$show_format" == "clean" ]]; then
                        # Display without counter, with color
                        echo -e "${CYAN}$world_name${NC}"
                        echo -e "   ${YELLOW}World ID  : ${NC}$world_id"
                        echo -e "   ${YELLOW}Server ID : ${NC}$server_id"
                    else
                        # Display with counter, with color
                        echo -e "${MAGENTA}$counter. ${CYAN}$world_name${NC}"
                        echo -e "   ${YELLOW}World ID: ${NC}$world_id"
                        echo -e "   ${YELLOW}Server ID: ${NC}$server_id"
                        ((counter++))
                    fi
                fi
            done
        fi
    done

    if [[ "$show_format" != "show" ]] && [ "$counter" -eq 1 ]; then
        logit "INFO" "No worlds found in the directory."
        return 1  # Error: no worlds found
    else
        logit "INFO" "Finished listing installed worlds."
        return 0  # Success: worlds found and listed
    fi
}

# Returns a count of how many worlds there are.
installed_worlds() {
    local server_dir world_dir
    local count=0  # Counter for the number of worlds found

    logit "DEBUG" "installed_worlds function started using PLAYERS_DIR = '$PLAYERS_DIR'"
    for server_dir in "$PLAYERS_DIR"/*; do
        if [ -d "$server_dir/worlds" ]; then
            for world_dir in "$server_dir/worlds"/*; do
                if [ -d "$world_dir" ] && [ -f "$world_dir/info.json" ]; then
                    local world_name=$(jq -r '.value0.worldName' "$world_dir/info.json")
                    local world_id=$(basename "$world_dir")
                    
                    # Log each world found
                    logit "INFO" "World found - '$world_name' with world_id = '$world_id'"

                    # Increment the world counter
                    ((count++))
                fi
            done
        fi
    done

    if [ $count -gt 0 ]; then
        logit "INFO" "$count worlds found."
    else
        logit "INFO" "No worlds found."
    fi

    # Return the count of worlds found
    echo $count
    return 0
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

# See if the Sapiens Server executable is installed
sapiens_installed(){
    # Check for sapiens executable
    local executable_name="linuxServer"
    logit "DEBUG" "Checking if exists: $SAPIENS_DIR/$executable_name"
    if [ -f "$SAPIENS_DIR/$executable_name" ]; then
        # Set the Sapiens Version
        SAPIENS_VERSION=$(get_sapiens_version)
        logit "INFO" "$executable_name found in $SAPIENS_DIR"
        logit "INFO" "Version: $SAPIENS_VERSION"
        return 0
    else
        logit "WARN" "$executable_name not found in $SAPIENS_DIR"
        return 1
    fi
}

#Check if our dependencies are installed and check if sapiens is installed.
dependencies_installed() {
    # Check for package dependencies by command availability
    for pkg in "${!DEPENDENCIES[@]}"; do
        # Capturing command output and suppressing console output
        if ! command_output=$(command -v "${DEPENDENCIES[$pkg]}" 2>/dev/null); then
            logit "INFO" "Missing dependency: $pkg (${DEPENDENCIES[$pkg]})"
            return 1  # Return with error if a dependency is not installed
        else
            # Log the success of found commands to the log file
            logit "DEBUG" "${DEPENDENCIES[$pkg]} found"
        fi
    done

    return 0 # There were no missing dependencies
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
    local version_line=$($SAPIENS_DIR/linuxServer --help | grep 'Version:')
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
    chmod +x sapiens.sh startworld.sh
}

# Function to select a world from the list
select_world() {
    local server_dir world_dir world_name world_id server_id
    local -a world_names world_ids server_ids
    local selection counter=0

    clear
    echo -e "${BRIGHT_CYAN}Available Worlds:${NC}"
    echo "----------------------------------------------------------------"
    for server_dir in "$PLAYERS_DIR"/*; do
        if [ -d "$server_dir/worlds" ]; then
            for world_dir in "$server_dir/worlds"/*; do
                if [ -d "$world_dir" ] && [ -f "$world_dir/info.json" ]; then
                    world_id=$(basename "$world_dir")
                    server_id=$(basename "$server_dir")
                    world_name=$(jq -r '.value0.worldName' "$world_dir/info.json")

                    # Increase counter and store details in arrays
                    ((counter++))
                    world_names[counter]="$world_name"
                    world_ids[counter]="$world_id"
                    server_ids[counter]="$server_id"

                    # Display the world with a counter
                    echo -e "${MAGENTA}$counter. ${CYAN}$world_name${NC}"
                    echo -e "   ${YELLOW}World ID: ${NC}$world_id"
                    echo -e "   ${YELLOW}Server ID: ${NC}$server_id"
                fi
            done
        fi
    done

    # If no worlds are found
    if [ $counter -eq 0 ]; then
        logit "INFO" "No worlds found in the directory."
        return 1  # Error: no worlds found
    fi

    # Prompt for selection
    while true; do
        echo "----------------------------------------------------------------"
        echo "Enter the number corresponding to the world you want to select:"
        read selection
        if [[ $selection =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= counter )); then
            WORLD_NAME="${world_names[$selection]}"
            WORLD_ID="${world_ids[$selection]}"
            SERVER_ID="${server_ids[$selection]}"
            logit "DEBUG" "Inside select_world - World selected : $WORLD_NAME"
            logit "DEBUG" "Inside select_world - World ID       : $WORLD_ID"
            logit "DEBUG" "Inside select_world - Server ID      : $SERVER_ID"
            return 0  # Valid selection
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Create a new world
create_world() {
    
    local new_world_default="Nameless Sapiens World"
    local new_world_name

    read -p "World Name [$new_world_default]): " new_world_name
    if [ -z "$new_world_name" ]; then
        logit "DEBUG" "User chose default world name $new_world_name"
        new_world_name=$new_world_default
    fi
    logit "INFO" "New world $new_world_name being created"
    echo "The new world '$new_world_name' is being created, please wait..."
    
    # Create the world and grab the process pid
    logit "INFO" "Creating new world: $SAPIENS_DIR/linuxServer --server-id '$SERVER_ID' --new '$new_world_name'"
    $SAPIENS_DIR/linuxServer --server-id "$SERVER_ID" --new "$new_world_name" >/dev/null 2>&1 &
    local pid=$!
    sleep 5     # Wait a bit to make sure the world creation is complete
    kill $pid   # Kill the linuxServer process
    sleep 2     # Wait a bit for it to be killed

    # Make sure the process was killed.
    if kill -0 $pid 2>/dev/null; then
        logit "WARN" "create_world process $pid was not able to be killed successfully."
        return 1  # Process not killed, implying failure
    fi

    # Attempt to retrieve the WORLD_ID of the new world
    local new_world_id=""
    local world_dir=""

    for world_dir in "$WORLDS_DIR"/*; do
        local info_json="$world_dir/info.json"
        if [[ -f "$info_json" ]]; then
            local current_world_name=$(jq -r '.worldName' "$info_json")
            if [[ "$current_world_name" == "$new_world_name" ]]; then
                new_world_id=$(basename "$world_dir")
                logit "INFO" "Newly created $new_world_name has World ID = $new_world_id"
                echo "$new_world_id"
                return 0 # All good, world created and returning new_world_id
            fi
        fi
    done

    logit "WARN" "create_world function was unable to find the newly created world ID for $new_world_id"
    return 2  # WORLD_ID not found
}

get_active_server_details(){
    if yesno "Advertise Server to the public in-game?"; then
        ADVERTISE="--advertise "
        echo "Server will be advertised."
    else
        ADVERTISE=""
        echo "Server will not be advertised."
    fi

    if yesno "If you don't mind helping the developer to fix bugs in Sapiens, do you want to send your log files on a crash?"; then
        PROVIDE_LOGS="--yes "
        echo "Log reporting Enabled."
    else
        PROVIDE_LOGS=""
        echo "No reports will be sent to the developer on a crash."
    fi

    # Helper function to read port from user or use default
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
    UDP_PORT=$(read_port "Enter UDP Port" "16161")

    # Calculate the Steam port, which is UDP port + 1
    STEAM_PORT=$((UDP_PORT + 1))

    # Read HTTP port from user or use default
    HTTP_PORT=$(read_port "Enter HTTP Port" "16168")

    # Ensure the Steam port does not conflict with the HTTP port
    while [ "$STEAM_PORT" -eq "$HTTP_PORT" ]; do
        echo "Conflict detected: HTTP port ($HTTP_PORT) cannot be the same as Steam port ($STEAM_PORT)."
        # Re-prompt for the HTTP port
        HTTP_PORT=$(read_port "Enter a different HTTP Port" "16168")
    done
}

