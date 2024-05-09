#!/usr/bin/env bash

# Script for starting the server. Its purpose is to start the server and automatically
# restart it if a non-zero argument is returned on exit, implying a crash. On a crash or a normal stop
# the log files are stored in the logs backup folder.

# Import the configuration
if [ ! -f "config.sh" ]; then
  echo "Error: config.sh file not found. Please ensure you run 'install.sh' first to generate the configuration for the scripts." | tee -a "$LOG_FILE"
  exit 1
else
  source config.sh
fi

LOG_FILE="start.log"
cd $SCRIPT_DIR

# Check if log file exists, clear it if it does, or create a new one if it doesn't
: > "$LOG_FILE"  # This command truncates or creates the log file

# Server lifecycle loop
while true; do
    # Check for no-restart flag before attempting to start the server
    cd $SCRIPT_DIR
    if [ -f "no-restart.flag" ]; then
        echo "No-restart flag found. Exiting without starting the server." | tee -a "$LOG_FILE"
        rm "no-restart.flag"  # Clean up the flag for future operations
        break
    fi

    # Start the server with the configured world's parameters.
    cd $GAME_DIR

    echo "./linuxServer $PROVIDE_LOGS$ADVERTISE--server-id '$SERVER_ID' --load '$WORLD_NAME' --port '$UDP_PORT' --http-port '$HTTP_PORT'" | tee -a "$LOG_FILE"
    ./linuxServer $PROVIDE_LOGS$ADVERTISE--server-id "$SERVER_ID" --load "$WORLD_NAME" --port "$UDP_PORT" --http-port "$HTTP_PORT"
    status=$?

    # Check the exit status of the command. If it's non-zero, assume it crashed,
    # save the logs and restart it.
    if [ $status -ne 0 ]; then
        # Server crashed. Back up the logs
        echo "Fatal Error: Sapiens Server crashed with code $status. Backing up logs and restarting in 5 seconds..." | tee -a "$LOG_FILE"
        cd $SCRIPT_DIR; ./backuplogs.sh
        sleep 5
        echo "Restarting world $WORLD_NAME..." | tee -a "$LOG_FILE"
    else
        sleep 5
        echo "Sapiens Server stopped gracefully." | tee -a "$LOG_FILE"
        cd $SCRIPT_DIR; ./backuplogs.sh
        break  # Exit the loop if the server stopped gracefully
    fi
done