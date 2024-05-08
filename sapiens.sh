#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Sapiens Server Manager.

# Source the bootstrap file
if ! source bootstrap.sh; then
    echo "Error: Failed to source bootstrap.sh. Ensure the file exists in the script directory and is readable."
    exit 1
fi

# Source the functions file
if ! source functions.sh; then
    echo "Error: Failed to source functions.sh. Ensure the file exists in the script directory and is readable."
    exit 1
fi

# Source the servercmd file
if ! source servercmd.sh; then
    echo "Error: Failed to source servercmd.sh. Ensure the file exists in the script directory and is readable."
    exit 1
fi

startup_sequence    # From bootstrap.sh

# Argument Handling - checks if any argument is provided
if [ "$#" -gt 0 ]; then
    if [ "$1" == "restart" ]; then
        restart_server silent
    else
        echo "Invalid argument: $1"
    fi
    exit 0
else
    # No arguments passed, run the UI Application Loop
    while true; do
        clear
        main_menu_ui
        case $? in
            1)  # Exit the application
                clear
                echo "Sapiens Server Manager exited."
                break
                ;;
            *)  # For all other cases, loop back to the main menu
                ;;
        esac
    done
fi
