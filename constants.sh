#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Constants for the script package. 

# Script package constants
SCRIPT_DIR="$HOME/sapiens-server"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
WORLD_BACKUP_DIR="$SCRIPT_DIR/world_backups"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_BACKUP_DIR="$SCRIPT_DIR/log_backups"
DEBUG_MODE="on"                                             # Set to "on" to enable debug logging, "off" to disable.
SCREEN_NAME="sapiens-server"
SHUTDOWN_WAIT=5                                             # How many seconds to wait for the screen session to end.
SCRIPT_NAME="Sapiens Linux Server Helper Scripts"
SCRIPT_VERSION="1.0.1"
GITHUB_URL="https://github.com/ChillGenXer/sapiens-server"

# Steam locations (Server executable)
STEAMCMD_DIR="$HOME/.local/share/Steam/steamcmd"
SAPIENS_DIR="$STEAMCMD_DIR/sapiens"
SAPIENS_BUILD_FILE="$SCRIPT_DIR/sapiens_build_id.txt"

# MajicJungle locations (World Data)
SERVER_ID="sapserver"
GAME_DATA_DIR="$HOME/.local/share/majicjungle/sapiens"
PLAYERS_DIR="$GAME_DATA_DIR/players"
WORLDS_DIR="$PLAYERS_DIR/$SERVER_ID/worlds"

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    current_script=$(basename "${BASH_SOURCE[0]}")
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    logit "INFO" "Attempt to run $current_script directly detected.  Please use sapiens.sh for all operations."
    exit 1
fi

# Function to validate that the constants are set correctly.
validate_constants() {
    # TODO
    sleep 0
}

# *****  System Constants *****

# Regular Colors
BLACK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow
BLUE='\033[0;34m'         # Blue
MAGENTA='\033[0;35m'      # Magenta
CYAN='\033[0;36m'         # Cyan
WHITE='\033[0;37m'        # White

# Bright Colors
BRIGHT_BLACK='\033[1;30m' # Bright Black (Gray)
BRIGHT_RED='\033[1;31m'   # Bright Red
BRIGHT_GREEN='\033[1;32m' # Bright Green
BRIGHT_YELLOW='\033[1;33m' # Bright Yellow
BRIGHT_BLUE='\033[1;34m'  # Bright Blue
BRIGHT_MAGENTA='\033[1;35m' # Bright Magenta
BRIGHT_CYAN='\033[1;36m'  # Bright Cyan
BRIGHT_WHITE='\033[1;37m' # Bright White

NC='\033[0m'        # Remove formatting
BOLD='\033[1m'      # Bold
UNDERLINE='\033[4m' # Underline

# Example usage of colors in echo statements
#echo -e "${RED}This text is red.${NC}"
#echo -e "${GREEN}This text is green.${NC}"
#echo -e "${YELLOW}This text is yellow.${NC}"
#echo -e "${BLUE}This text is blue.${NC}"
#echo -e "${BRIGHT_RED}This text is bright red.${NC}"
#echo -e "${BRIGHT_GREEN}This text is bright green.${NC}"
#echo -e "${BRIGHT_YELLOW}This text is bright yellow.${NC}"
#echo -e "${BRIGHT_BLUE}This text is bright blue.${NC}"