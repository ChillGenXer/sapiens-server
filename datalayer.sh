#!/usr/bin/env bash
# Author: ChillGenXer (chillgenxer@gmail.com)
# Description: Functions for managing the sapservermgr.sh database.

# Check if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local current_script=$(basename "${BASH_SOURCE[0]}")
    echo "The script ($current_script) is a library file, and not meant to be run directly. Run sapiens.sh only."
    logit "INFO" "Attempt to run $current_script directly detected.  Please use sapiens.sh for all operations."
    exit 1
fi

# Function to initialize the database and create the table if it doesn't exist
db_initialize() {
    # SQL command to create the table if it does not exist
    local create_table_sql="CREATE TABLE IF NOT EXISTS port_group (
        port_group_id INTEGER PRIMARY KEY AUTOINCREMENT,
        udp_port INTEGER,
        steam_port INTEGER,
        http_port INTEGER,
        port_group_name TEXT
    );"

    # Check if the database file exists. If not, create the database and table.
    if [ ! -f "$SAPSERVER_DB" ]; then
        logit "INFO" "Database not found. Creating database."
    fi

    # Execute the SQL command to create the table
    sqlite3 $SAPSERVER_DB "$create_table_sql"
    if [ $? -eq 0 ]; then
        logit "INFO" "Database initialized successfully."
    else
        logit "ERROR" "Failed to initialize database $SAPSERVER_DB."
    fi
}

# Function to manage the port group table
manage_port_groups() {
    local operation="$1"
    local port_group_id="$2"
    local udp_port="$3"
    local steam_port="$4"
    local http_port="$5"
    local port_group_name="$6"

    case "$operation" in
        create)
            # Creating a new port group record
            sqlite3 $SAPSERVER_DB "INSERT INTO port_group (udp_port, steam_port, http_port, port_group_name) VALUES ($udp_port, $steam_port, $http_port, '$port_group_name');"
            ;;
        read)
            # Reading a particular record by port_group_id
            sqlite3 $SAPSERVER_DB "SELECT * FROM port_group WHERE port_group_id = $port_group_id;"
            ;;
        update)
            # Updating a specific record
            sqlite3 $SAPSERVER_DB "UPDATE port_group SET udp_port = $udp_port, steam_port = $steam_port, http_port = $http_port, port_group_name = '$port_group_name' WHERE port_group_id = $port_group_id;"
            ;;
        list)
            # Listing all records in the table
            sqlite3 $SAPSERVER_DB "SELECT * FROM port_group;"
            ;;
        *)
            echo "Invalid operation. Available operations: create, read, update, list"
            ;;
    esac
}