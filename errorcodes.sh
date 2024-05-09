#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Error code array to leverage bash script exit codes for better error handling.

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is a library script file, and not meant to be run directly. Run sapiens.sh only."
    exit 1
fi

declare -A ERRORCODE=(
    [0]="Operation completed successfully."
    [1]="Error 1"
    [2]="Error 2"
    [3]="Error 3"
    [4]="Error 4"
    [5]="Error 5"
)
