#!/bin/bash

# Location of where the server executable is located.  If you followed the readme instructions this probably doesn't need to be changed.
GAME_DIR="~/.local/share/Steam/steamcmd/sapiens"

# Location of where the world is.  You will need to see what was generated and set it here and replace the CAPS_VALUES to match what you have.
WORLD_DIR="~/.local/share/majicjungle/sapiens/players/PLAYER_NUMBER_FOLDER_NAME/worlds/WORLD_NUMBER_FOLDER_NAME"

# The folder where the backup command will send your world archive.  This folder was created with the git package, just change as necessary. 
BACKUP_DIR="~/sapiens-server/world_backups"

# World Name.  This is the name used in the game that shows up on the map as well as the server listing.
WORLD_NAME="My New World"

# Network settings.  These are the defaults, change as necessary.  Please note there is 1 additional port that needs to be opened on your
# firewall that will be +1 above the UDP_PORT.  So using the defaults you would have to open 16161 and 16162 for UDP and 16168 for TCP 
# redirected to your server
UDP_PORT=16161
HTTP_PORT=16168

# Best to leave this as is.
SCREEN_NAME="sapiens-server"
