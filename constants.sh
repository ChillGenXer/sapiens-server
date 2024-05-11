#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Error code array to leverage bash script exit codes for better error handling.

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local current_script=$(basename "${BASH_SOURCE[0]}")
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    logit "INFO" "Attempt to run $current_script directly detected.  Please use sapiens.sh for all operations."
    exit 1
fi

#Installation Constants
VERSION="0.5.0"
SCRIPT_DIR="$HOME/sapiens-server"
START_LOG_FILE="$SCRIPT_DIR/start.log"
SAPSERVER_LOG="$SCRIPT_DIR/sapservermgr.log"
SAPSERVER_DB="$SCRIPT_DIR/sapservermgr.db"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
GAME_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"
SAPIENS_DIR="$HOME/.local/share/majicjungle/sapiens"
PLAYERS_DIR="$SAPIENS_DIR/players"  # Used in manage_worlds.refresh_worldlist
# World Servers
BACKUP_DIR="$SCRIPT_DIR/world_backups"
LOG_BACKUP_DIR="$SCRIPT_DIR/log_backups"
ENET_LOG="$SAPIENS_DIR/enetServerLog.log"

SERVER_ID="$(whoami)"               # The standard server-id (/players) for an install will be the linux account
SCREEN_NAME="sapiens-server"
IP_ADDRESS=$(ip addr show $(ip route show default | awk '/default/ {print $5}') | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
PUBLIC_IP_ADDRESS=$(curl -s https://api.ipify.org)
# Array of dependencies for the server to run and needed by the script to work.  It is in an array for clarity
# with the cell name being the actual package name for use in apt package manager, while the value is the command
# used to check if the package is present.
declare -A DEPENDENCIES=(
    [screen]=screen         # Used to virtualize the server so the console doesn't need to remain open.
    [psmisc]=killall        # Needed for the killall command
    [steamcmd]=steamcmd     # Steam commandline tool for installing and updating the Sapiens server.
    [jq]=jq                 # Used for managing json files.
    [procps]=ps             # process grep
    [dialog]=dialog         # Console UI functions
    [sqlite3]=sqlite3        # SQLite Database.
)

declare -A ERRORCODE=(
    [0]="Operation completed successfully."
    [1]="Error 1"
)




# Reset
NC='\033[0m' # No Color

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

# Bold
BOLD='\033[1m'

# Underline
UNDERLINE='\033[4m'

# Example usage of colors in echo statements
#echo -e "${RED}This text is red.${NC}"
#echo -e "${GREEN}This text is green.${NC}"
#echo -e "${YELLOW}This text is yellow.${NC}"
#echo -e "${BLUE}This text is blue.${NC}"
#echo -e "${BRIGHT_RED}This text is bright red.${NC}"
#echo -e "${BRIGHT_GREEN}This text is bright green.${NC}"
#echo -e "${BRIGHT_YELLOW}This text is bright yellow.${NC}"
#echo -e "${BRIGHT_BLUE}This text is bright blue.${NC}"