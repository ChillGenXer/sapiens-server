#!/usr/bin/env bash

# Script for starting the server.  Its purpose is to start the server and automatically
# restart it if a non-zero argument is returned on exit, implying a crash.
# Please note you have to create a world first, this script will not do it automatically.  
# Run linuxServer --help to see the commands.

WORLD_NAME="Test World"
SERVER_ID="chillgenxer"      # This gets generated based on what you provide when you use the --new command to generate a world.
UDP_PORT="16161"           # Default UDP port. Port forwarding required for advertise.
#STEAM_UDP_PORT="16162"    # This is not set manually but calculated as UDP_PORT + 1.  Port forwarding required for advertise.
HTTP_PORT="16168"          # Default HTTP port. Port forwarding required for advertise.
#ADVERTISE="--advertise "  # Uncomment this if you want to have your server listed publicly in-game. Space in value is needed.
PROVIDE_LOGS="--yes "      # Uncomment if you want to provide the developer with logs on a server crash. Space in value is needed.
SAPIENS_DIR="$HOME/.local/share/Steam/steamcmd/sapiens"  # Location to your linuxServer. You might need to verify this is correct.

# Server lifecycle loop
while true; do
    # Start the server with the configured world's parameters.
    cd $SAPIENS_DIR
    echo "cd $SAPIENS_DIR"
    echo "linuxServer Starting: ./linuxServer $PROVIDE_LOGS$ADVERTISE--server-id '$SERVER_ID' --load '$WORLD_NAME' --port '$UDP_PORT' --http-port '$HTTP_PORT'"
    ./linuxServer $PROVIDE_LOGS$ADVERTISE--server-id "$SERVER_ID" --load "$WORLD_NAME" --port "$UDP_PORT" --http-port "$HTTP_PORT"
    status=$?
    # Check the exit status of the command.  If it's non-zero we will assume it crashed,
    # save the logs and restart it.
    if [ $status -ne 0 ]; then
        # Server crashed.  Back up the logs
        echo "Fatal Error: World '$WORLD_NAME' crashed with code $status."
        echo "Restarting in 5 seconds..."       
    else
        echo "World '$WORLD_NAME' stopped gracefully with exit code $status."
        break  # Exit the loop if the server stopped gracefully
    fi
    # Add a delay before restarting the server
    sleep 5
	echo "Restarting world $WORLD_NAME..."
done