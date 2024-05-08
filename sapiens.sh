#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Sapiens Server Manager.

# Source the required files
# List of files to source
required_files=("bootstrap.sh" "functions.sh" "servercmd.sh")

# Source the required files
for file in "${required_files[@]}"; do
    if ! source "$file"; then
        echo "Error: Failed to source $file. Ensure the file exists in the script directory and is readable."
        exit 1
    fi
done

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
