#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Script file library for the UI screen functions.

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is a library script file, and not meant to be run directly. Run sapiens.sh only."
    exit 1
fi

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
        1) 
            if refresh_worldlist; then
                manage_world_menu_ui
            else
                dialog --clear --msgbox "There are no worlds installed on account $(whoami). Create a new one to get started." 8 70
            fi ;;
        2) 
            if refresh_worldlist; then
                select_world_ui
                setup_server_ui
            else
                dialog --clear --msgbox "There are no worlds installed on account $(whoami). Create a new one to get started." 8 70
            fi ;;
        3) create_world_ui ;;
        4) clear; upgrade_sapiens ;;
        5) clear; install_dependencies ;;
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
            "6" "Set Server Restart Schedule"
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
            6) auto_restart_ui ;;
            7) backup_world ;;
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

    # Get a human-friendly value for PROVIDE_LOGS
    if [[ "$PROVIDE_LOGS" == "--yes " ]]; then
        send_logs="Yes"
    else
        send_logs="No"
    fi

    # Assemble the server information
    local server_info="---------------------------------------------------------------------\n"
    server_info+="World Name                : $WORLD_NAME\n"
    server_info+="Local IP Address          : $IP_ADDRESS\n"
    server_info+="UDP Port                  : $UDP_PORT\n"
    server_info+="Steam Port                : $((UDP_PORT + 1))\n"  # Calculate Steam port on the fly
    server_info+="HTTP Port                 : $HTTP_PORT\n"
    server_info+="Advertising In-Game       : $( [ "$ADVERTISE" == "--advertise " ] && echo "Yes" || echo "No")\n"
    server_info+="Send logs on crash        : $send_logs\n"
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

    # Ask if the server should be advertised with the default set to the existing value
    if dialog --clear --yesno "Advertise server to the public in-game? Current setting: $( [ "$ADVERTISE" == "--ADVERTISE " ] && echo "Yes" || echo "No")" 0 0; then
        ADVERTISE="--advertise " # Need the space for the server launch in start.sh.
    else
        ADVERTISE=""
    fi

    # Ask if logs should be sent on crash
    if dialog --clear --yesno "Do you want to send your log files to help the developer fix bugs on a crash?" 10 60; then
        PROVIDE_LOGS="--yes "   # Need the space for the server launch in start.sh.
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
    local world_name=$(dialog --clear --inputbox "Enter the name for the new world (or leave empty for 'Nameless Sapiens World'):" 10 60 3>&1 1>&2 2>&3)
    
    # Default the world name if none is provided
    [ -z "$world_name" ] && world_name="Nameless Sapiens World"

    # Display an infobox while creating the world
    dialog --title "Creating World" --infobox "Please wait, creating world $world_name..." 0 0 &
    local dialog_pid=$!

    # Call the create_world function and capture the output
    local world_id=$(create_world "$world_name")
    local status=$?

    # Kill the infobox after the world creation is complete
    kill $dialog_pid

    # Tell the user what happened
    case $status in
        0) dialog --clear --msgbox "$world_name creation completed successfully with World ID: $world_id. You can now select it as the active world in the main menu." 0 0 ;;
        1) dialog --clear --msgbox "Failed to terminate the server process correctly. Please check the system." 0 0 ;;
        2) dialog --clear --msgbox "Failed to find the newly created world. Please verify and configure manually." 0 0 ;;
        *) dialog --clear --msgbox "An unexpected error occurred." 0 0 ;;
    esac
}

# Provides a visual progress bar for using the sleep command
sleep_ui() {
    local message=$1
    local waittime=$2
    local increment=$((100 / waittime))  # Calculate the increment per second.
    local progress=0                     # Initialize progress.

    {
        for (( i=1; i <= waittime; i++ )); do
            progress=$((increment * i))  # Calculate progress based on current loop iteration.
            if ((progress > 100)); then  # Cap the progress at 100%.
                progress=100
            fi
            echo $progress               # Send current progress to dialog.
            sleep 1                      # Wait for a second.
        done
        echo 100                         # Ensure the progress reaches 100% at the end.
    } | dialog --clear --gauge "$message" 6 50 0
}

auto_restart_ui() {
    local interval

    # Loop until valid input is received or the user chooses to cancel
    while true; do
        # Using dialog to get user input for restart interval
        exec 3>&1
        interval=$(dialog --inputbox "Enter the auto-restart interval in hours (1-24, 0 to disable):" 10 50 2>&1 1>&3)
        exit_status=$?
        exec 3>&-

        # Check if user chose to cancel
        if [ $exit_status -ne 0 ]; then
            dialog --msgbox "You chose to cancel." 5 40
            return 0
        fi

        # Validate the input before confirming it to the user
        if [[ "$interval" =~ ^[0-9]+$ ]] && (( interval == 0 || ( interval >= 1 && interval <= 24 ) )); then
            # Ask the user to confirm creating the schedule
            exec 3>&1
            confirmation=$(dialog --yesno "Restart the world every $interval hour(s) - create the schedule?" 7 50 2>&1 1>&3)
            confirm_status=$?
            exec 3>&-
            if [ $confirm_status -eq 0 ]; then
                # If user confirms, call auto_restart and break the loop
                auto_restart $interval
                return 0
            else
                # If user cancels at this stage, return to the main calling UI script
                return 0
            fi
        else
            dialog --msgbox "Invalid input: Interval must be a number of hours between 1 and 24 or 0 to disable." 6 50
            # Continue the loop to re-prompt
        fi
    done
}