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
echo -e "${RED}This text is red.${NC}"
echo -e "${GREEN}This text is green.${NC}"
echo -e "${YELLOW}This text is yellow.${NC}"
echo -e "${BLUE}This text is blue.${NC}"
echo -e "${BRIGHT_RED}This text is bright red.${NC}"
echo -e "${BRIGHT_GREEN}This text is bright green.${NC}"
echo -e "${BRIGHT_YELLOW}This text is bright yellow.${NC}"
echo -e "${BRIGHT_BLUE}This text is bright blue.${NC}"