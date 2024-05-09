#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file Library of functions to manage installed worlds.

# Data structures to hold the installed world information.
declare -a server_ids
declare -a world_ids
declare -a world_names
declare -a display_lines

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

# Create a new world
create_world() {
    local new_world_name=$1
    local base_dir="$PLAYERS_DIR/$SERVER_ID/worlds"

    # Default the world name if none is provided
    if [ -z "$new_world_name" ]; then
        new_world_name="Nameless Sapiens World"
    fi

    # Create the world and grab the process pid
    $GAME_DIR/linuxServer --server-id "$SERVER_ID" --new "$new_world_name" >/dev/null 2>&1 &
    pid=$!

    sleep 5     # Wait a bit to make sure the world creation is complete
    kill $pid   # Kill the linuxServer process
    sleep 2     # Wait a bit for it to be killed

    # Make sure the process was killed.
    if kill -0 $pid 2>/dev/null; then
        # It's not able to kill the process.  TODO: There could still be a world?  Not sure if this will even happen.
        return 1
    fi

    # Attempt to retrieve the WORLD_ID of the new world
    for world_dir in "$base_dir"/*; do
        info_json="$world_dir/info.json"
        if [[ -f "$info_json" ]]; then
            current_world_name=$(jq -r '.value0.worldName' "$info_json")
            if [[ "$current_world_name" == "$WORLD_NAME" ]]; then
                local new_world_id=$(basename "$world_dir")
                break
            fi
        fi
    done

    # Validate if WORLD_ID was successfully retrieved
    if [[ -z "$new_world_id" ]]; then
        dialog --clear --msgbox "Failed to find the newly created world. Please verify and configure manually." 10 50
    else
        dialog --clear --msgbox "$WORLD_NAME creation completed successfully with World ID: $new_world_id. You can now select it as the active world in the main menu." 10 70
    fi
}

# Restore world from an archive file
restore_world() {
    local world_archive_path=1$
}

# Function to backup the world folder to the specified backup directory.
backup_world() {
    # TODO Error handling
    local new_server_id=$1
    local new_world_name=$2

    # Ensure that the server is stopped.
    stop_server silent

    echo "Backing up the world '$WORLD_NAME'..."
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="sapiens_backup_$TIMESTAMP.tar.gz"
    cd "$PLAYERS_DIR/$SERVER_ID/worlds"
    # Archive the specific world directory, including its name in the archive
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"

    dialog --clear --msgbox "'$WORLD_NAME' has been backed up.  Don't forget to restart your world." 10 70
}
