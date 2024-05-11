#!/usr/bin/env bash

# Script for starting the server.  Its purpose is to start the server and automatically
# restart it if a non-zero argument is returned on exit, implying a crash.  On a crash or a normal stop
# the log files are stored in the logs backup folder.

# Import the configuration
if [ ! -f "config.sh" ]; then
  echo "Error: config.sh file not found.  Please ensure you run 'install.sh' first to generate the configuration for the scripts."
  exit 1
else
  source $CONFIG_FILE
fi

# Server lifecycle loop
while true; do
    # Start the server with the configured world's parameters.
    # TODO: This is cludgy, you need to fix this up.
    cd $GAME_DIR
    if [ "$ADVERTISE" == "true" ]; then
        echo "./linuxServer $PROVIDE_LOGS--advertise --server-id '$SERVER_ID' --load '$WORLD_NAME' --port '$UDP_PORT' --http-port '$HTTP_PORT'"
        ./linuxServer $PROVIDE_LOGS--advertise --server-id "$SERVER_ID" --load "$WORLD_NAME" --port "$UDP_PORT" --http-port "$HTTP_PORT"
        status=$?
    else
        echo "./linuxServer $PROVIDE_LOGS--server-id '$SERVER_ID' --load '$WORLD_NAME' --port '$UDP_PORT' --http-port '$HTTP_PORT'"
        ./linuxServer --server-id "$SERVER_ID" --load "$WORLD_NAME" --port "$UDP_PORT" --http-port "$HTTP_PORT"
        status=$?
    fi

    # Check the exit status of the command.  If it's non-zero we will assume it crashed,
    # save the logs and restart it.
    if [ status -ne 0 ]; then
        # Server crashed.  Back up the logs
        echo "Fatal Error: Sapiens Server crashed with code $? . Backing up logs and restarting in 5 seconds..."       
        cd $SCRIPT_DIR;./backuplogs.sh
    else
        echo "Sapiens Server stopped gracefully."
        cd $SCRIPT_DIR;./backuplogs.sh
        break  # Exit the loop if the server stopped gracefully
    fi

    # Add a delay before restarting the server
    sleep 5
	echo "Restarting world $WORLD_NAME..."
done
