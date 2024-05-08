#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Library of functions to manage installed worlds.

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
    local new_server_id=$1
    local new_world_name=$2
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
    cd "$SAPIENS_DIR/players/$SERVER_ID/worlds"
    # Archive the specific world directory, including its name in the archive
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$WORLD_ID"

    dialog --clear --msgbox "'$WORLD_NAME' has been backed up.  Don't forget to restart your world." 10 70
}
