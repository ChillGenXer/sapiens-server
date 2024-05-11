#!/usr/bin/env bash

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local current_script=$(basename "${BASH_SOURCE[0]}")
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    logit "INFO" "Attempt to run $current_script directly detected.  Please use sapiens.sh for all operations."
    exit 1
fi

# Gets the current version of the Sapiens linuxServer executable
get_sapiens_version() {
    #Run the --help command on the server executable and cut out the version number
    local version_line=$($GAME_DIR/linuxServer --help | grep 'Version:')
    SAPIENS_VERSION=$(echo "$version_line" | cut -d':' -f2 | xargs)
    logit "INFO" "Sapiens linuxServer version $SAPIENS_VERSION"
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
        logit "DEBUG" "$executable_name found in $steamcmd_dir"
    else
        logit "DEBUG" "$executable_name not found in $steamcmd_dir"

    fi
    logit "INFO" "SAPIENS_INSTALLED=$SAPIENS_INSTALLED"
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

# Function to select a world from the list
select_world() {
    local selection counter=${#display_lines[@]}

    for line in "${display_lines[@]}"; do
        echo "$line"
    done

    while true; do
        echo "Enter the number corresponding to the world you want:"
        read selection

        if [[ $selection -ge 1 && $selection -le $counter ]]; then
            SERVER_ID="${server_ids[$selection]}"
            WORLD_ID="${world_ids[$selection]}"
            WORLD_NAME="${world_names[$selection]}"
            return 0  # Valid selection
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Create a new world
create_world() {
    
    local new_world_default="Nameless Sapiens World"
    local new_world_name = ""

    read -p "World Name [$new_world_default]): " new_world_name
    if [ -z "$new_world_name" ]; then
        logit "DEBUG" "User chose default world name $new_world_name"
        new_world_name=$new_world_default
    fi
    logit "INFO" "New world $new_world_name being created"
    
    # Create the world and grab the process pid
    logit "INFO" "Creating new world: $GAME_DIR/linuxServer --server-id '$SERVER_ID' --new '$new_world_name'"
    $GAME_DIR/linuxServer --server-id "$SERVER_ID" --new "$new_world_name" >/dev/null 2>&1 &
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
        logit "INFO" "refresh_worldlist found at least one world."
        return 0  # Success: at least one world found
    else
        logit "INFO" "refresh_worldlist did not find any worlds."
        return 1  # Error: no worlds found
    fi
}
