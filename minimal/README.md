# Sapiens Linux Server Helper Scripts - Minimal - Just the Basics
**Last tested Sapiens Dedicated Server Version: 0.5.0.47**

This contains a set of scripts to give you the bare minimum install, basically a working<br>
linuxServer executable.  It also contains a script for how to run an update when new versions<br>
released.  It also contains a script to run the server itself that runs it in a loop, restarting<br>
if it crashes.

This package assumes you have an **Ubuntu 23.10 or greater**.  It hasn't been tested on other distributions.

## Configuration ##

**minstall.sh & update.sh** - This is the path to the provided steamcmd script for updating Sapiens.  If you have moved these files this will need to be set. steamcmd wants the file where it runs, otherwise you specifically have to tell it where it is.

``STEAM_UPDATE_SCRIPT="~/sapiens-server/minimal/steamupdate.txt"``

**startworld.sh** - The following defaults have been provided, if you want to use this script fill in your values here.

``$WORLD_NAME="Your World Name"
$SERVER_ID="CHANGE_ME"      # This gets generated based on what you provide when you use the --new command to generate a world.
$UDP_PORT="16161"           # Default UDP port. Port forwarding required for advertise.
#$STEAM_UDP_PORT="16162"    # This is not set manually but calculated as UDP_PORT + 1.  Port forwarding required for advertise.
$HTTP_PORT="16168"          # Default HTTP port. Port forwarding required for advertise.
#$ADVERTISE="--advertise "  # Uncomment this if you want to have your server listed publicly in-game. Space in value is needed.
$PROVIDE_LOGS="--yes "      # Uncomment if you want to provide the developer with logs on a server crash. Space in value is needed.
$SAPIENS_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"  # Location to your linuxServer. You might need to verify this is correct.``
