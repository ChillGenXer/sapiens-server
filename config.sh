#!/bin/bash

#Location of where the server software is located.  If you followed the tutorial you probably just need to change YOUR_USERNAME.  Don't use
# "~" to shorten the home directory, I had some problems with it not being interpreted correctly in the script.
GAME_DIR="/home/YOUR_USERNAME/.local/share/Steam/steamcmd/sapiens"

#Location of where the world is.  You will need to see what was generated and set it here.
WORLD_DIR="/home/YOUR_USERNAME/.local/share/majicjungle/sapiens/players/PLAYER_NUMBER_FOLDER_NAME/worlds/WORLD_NUMBER_FOLDER_NAME"

#The folder where the backup command will send your world archive.  This folder was created with the git package, just change as necessary. 
BACKUP_DIR="/home/YOUR_USERNAME/sapiens-server/world_backups"

#World Name.  This is the name used in the game that shows up on the map as well as the server listing.
WORLD_NAME="Name of the World"

#Network settings.  These are the defaults, change as necessary.
UDP_PORT=16161
HTTP_PORT=16168

#Best to leave this as is.
SCREEN_NAME="sapiens-server"
