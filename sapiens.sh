#!/usr/bin/env bash

# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Sapiens Server Manager.

# Source the required files
required_files=("bootstrap.sh" "ui_functions.sh" "servercmd.sh")

for file in "${required_files[@]}"; do
    if ! source "$file"; then
        echo "Error: Failed to source $file. Ensure the file exists in the script directory and is readable."
        exit 1
    fi
done

# Do initial checks to see if something needs to be installed.
startup_sequence    # From bootstrap.sh

# Commandline argument handling or main UI loop?
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
                shutdown_sequence
                break
                ;;
            *)  # For all other cases, loop back to the main menu
                ;;
        esac
    done
fi
