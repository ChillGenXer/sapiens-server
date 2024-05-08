#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file to externalize a few of the functions.

# Application Main Menu
main_menu_ui() {
    # Display the active world if one is selected
    local active_world_msg="Active World: ${WORLD_NAME:-'None Selected'}"

    local options=(
        "1" "Manage the Active World"
        "2" "Change the Active World"
        "3" "Create a New World"
        "4" "Update Sapiens Server From Steam"
        "5" "Reinstall Dependencies"
        "6" "Quit Sapiens Server Manager"  # Adding an explicit exit option
    )
    
    local user_choice=$(dialog --clear --title "Sapiens Server Manager - $active_world_msg" --menu "Choose an option:" 20 78 6 "${options[@]}" 3>&1 1>&2 2>&3)

    case $user_choice in
        1) manage_world_menu_ui ;;
        2) 
            if refresh_worldlist; then
                select_world_ui
                setup_server_ui
            else
                dialog --clear --msgbox "There are no worlds installed on account $(whoami). Create a new one to get started." 8 70
            fi
        ;;
        3) create_world_ui ;;
        4) upgrade_sapiens ;;
        5) install_dependencies ;;
        6) 
            return 1  # Exit application
        ;;
        '') 
            return 1  # Signal to exit application if user pressed ESC or Cancel
        ;;
        *) 
            dialog --clear --msgbox "Invalid choice. Please try again." 8 45
        ;;
    esac

    return 0
}

# Menu for managing the active world
manage_world_menu_ui() {
    while true; do
        local options=(
            "1" "Open Console"
            "2" "Start Server"
            "3" "Restart Server"
            "4" "Stop Server"
            "5" "Hard Stop Server"
            "6" "Toggle Auto Restart"
            "7" "Backup Server"
            "8" "Show Active World Info"
            "9" "Exit to Main Menu"
            "10" "Quit Sapiens Server Manager"
        )
        
        local user_choice=$(dialog --clear --title "Manage Active World - $WORLD_NAME" --menu "Select an operation for the active world:" 20 78 10 "${options[@]}" 3>&1 1>&2 2>&3)
        
        case $user_choice in
            1) open_console ;;
            2) start_server ;;
            3) restart_server ;;
            4) stop_server ;;
            5) hardstop_server ;;
            6) auto_restart ;;
            7) backup_server ;;
            8) active_world_info_ui ;;
            9) 
                break ;;  # Exit to the main menu
            10) 
                clear
                echo "Sapiens Server Manager exited..."
                exit 0  # Exit the script cleanly
            ;;
            '')  # Handle ESC or empty input, equivalent to pressing 'Cancel'
                break
            ;;
            *)  # Handle invalid choice
                dialog --clear --msgbox "Invalid choice. Please try again." 8 45
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
        "--yes ")
            send_logs="Yes"
            ;;
        "--yes-upload-world ")
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
    dialog --clear --title "Active World Information" --msgbox "$server_info" 20 78
}

# Function to display and select the active world
select_world_ui() {
    refresh_worldlist

    # Check the exit status of the last command
    if [ $? -ne 0 ]; then
        dialog --clear --msgbox "No worlds found installed for $(whoami)." 10 50
        return 1  # Return an error code if refresh_worldlist failed
    fi

    # Prepare a menu using dialog with available worlds
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
    local selection=$(dialog --clear --menu "Choose a world to manage:" $height $width $menu_height "${options[@]}" 3>&1 1>&2 2>&3)

    # Handle the user's selection or cancellation
    if [ $? -eq 0 ] && [ -n "$selection" ]; then
        local actual_index=$((selection))
        SERVER_ID="${server_ids[$actual_index]}"
        WORLD_ID="${world_ids[$actual_index]}"
        WORLD_NAME="${world_names[$actual_index]}"
        echo "Selected World: $WORLD_NAME (Server ID: $SERVER_ID, World ID: $WORLD_ID)"
        return 0  # Valid selection
    else
        dialog --clear --msgbox "No selection made or cancelled." 10 50
        return 1  # User cancelled or closed the menu
    fi
}

# Function to configure the active world
setup_server_ui() {
    # Get the server name with a default value, defaulting to the existing SERVER_NAME or a placeholder
    SERVER_NAME=$(dialog --clear --inputbox "Enter server name:" 10 60 "${SERVER_NAME:-'My Server Name'}" 3>&1 1>&2 2>&3)
    SERVER_NAME=${SERVER_NAME:-"My Server Name"}

    # Ask if the server should be advertised with the default set to the existing value
    if dialog --clear --yesno "Advertise server to the public in-game? Current setting: $( [ "$ADVERTISE" == "true" ] && echo "Yes" || echo "No")" 10 60; then
        ADVERTISE="true"
    else
        ADVERTISE="false"
    fi

    # Ask if logs should be sent on crash
    if dialog --clear --yesno "Do you want to send your log files to help fix bugs on a crash?" 10 60; then
        PROVIDE_LOGS="--yes "
        # Ask if world data should also be sent
        if dialog --clear --yesno "Do you also want to send a copy of your world (can take long for large worlds)?" 10 60; then
            PROVIDE_LOGS="--yes-upload-world "
        fi
    else
        PROVIDE_LOGS=""
    fi

    # Get the UDP port, using the existing UDP_PORT if not provided
    UDP_PORT=$(dialog --clear --inputbox "Enter UDP Port:" 10 60 "$UDP_PORT" 3>&1 1>&2 2>&3)
    UDP_PORT=${UDP_PORT:-$UDP_PORT}

    # Calculate the Steam port, which is UDP port + 1
    STEAM_PORT=$((UDP_PORT + 1))

    # Get the HTTP port, using the existing HTTP_PORT if not provided, and ensure it does not conflict with the Steam port
    HTTP_PORT=$(dialog --clear --inputbox "Enter HTTP Port:" 10 60 "$HTTP_PORT" 3>&1 1>&2 2>&3)
    HTTP_PORT=${HTTP_PORT:-$HTTP_PORT}
    while [ "$STEAM_PORT" -eq "$HTTP_PORT" ]; do
        HTTP_PORT=$(dialog --clear --inputbox "Conflict detected: HTTP port ($HTTP_PORT) cannot be the same as Steam port ($STEAM_PORT). Enter a different HTTP Port:" 10 60 "$HTTP_PORT" 3>&1 1>&2 2>&3)
    done

    # Rewrite the config file
    create_config

    # Display summary of configuration
    active_world_info_ui
}

# Create a new Sapiens world via linuxServer --new
create_world_ui() {
    # Prompt for the world name
    WORLD_NAME=$(dialog --clear --inputbox "Enter the name for the new world (or leave empty for 'Nameless Sapiens World'):" 10 60 3>&1 1>&2 2>&3)
    
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
            dialog --clear --msgbox "Failed to create world. Please try again." 10 50
            return 1
        fi
        echo 100
    } | dialog --clear --gauge "Please wait, creating the world..." 6 50 0

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
        dialog --clear --msgbox "Failed to find the newly created world. Please verify and configure manually." 10 50
    else
        dialog --clear --msgbox "$WORLD_NAME creation completed successfully with World ID: $WORLD_ID. You can now select it as the active world in the main menu." 10 70
    fi
}
