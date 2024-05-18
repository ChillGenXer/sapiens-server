# Sapiens Linux Server Helper Scripts
- **Last tested Sapiens Dedicated Server Version: 0.5.0.54**

This repository offers a comprehensive command line interface for the installation and management of the Sapiens Dedicated Server on a Linux Ubuntu machine. These scripts simplify the process of running the server, performing updates, and managing the server's life cycle.

## Compatibility Note

These scripts were developed and thoroughly tested on Ubuntu 23.10 and are designed to run in a Bash environment with `apt` as the package manager. Earlier versions of Ubuntu should work (22.04 LTS). While efforts have been made to ensure compatibility across different Linux distributions, the functionality may vary outside the tested environment. If you encounter issues on other distributions please report them. This will help me assess the feasibility of extending compatibility or provide specific workarounds.

## Prerequisites

It is advisable to run the server within a dedicated user account. This setup takes advantage of how SteamCMD installs and manages the game's executable and related files within the `.local` directory of a user's home directory. While setting up a new user account is not mandatory, doing so can help maintain a clean and organized environment, especially useful for isolating the server from other system processes or personal use files.  While some constants can be changed in constants.sh, the script hasn't been thoroughly tested by making extensive changes to these constants.  So basically it is best to set up a dedicated user and follow the instructions here.

### Configuring a Dedicated User (If Required)

If you choose to set up a new user account for the server, follow these steps:

1. **Create the User**: This step creates a new user which will be used exclusively to operate the server.

    ```bash
    sudo adduser sapserver
    ```

2. **Grant Sudo Access**: Provide `sudo` access to allow the user to install necessary software and manage server settings. This access is controlled and does not compromise the security principles of running server processes.

    ```bash
    sudo usermod -aG sudo sapserver
    ```

## Installation

**It is best to start fresh and delete any previous version installed**. As long as you use the same user account your old world or worlds will be detected by the script.

**Important**: Before deleting any old `sapiens-server` folder, ensure to back up any important data from `world_backups` and `log_backups`.

Run the clone command in the home directory and it will create a folder `sapiens-server` where the scripts will reside:

```bash
git clone https://github.com/ChillGenXer/sapiens-server.git
cd sapiens-server

# Make the install script executable
chmod +x sapiens.sh

# Run the install script
./sapiens.sh config
```

Walk through the installation guide in the script and you should end up with a configured world, ready to run.

## Configuration

Once you have a configured world before you start it for the first time you can edit the `config.lua` file in the world directory to customize your server settings. This file is generated by the game for the world and can be edited using the `./sapiens.sh worldconfig` command, which opens the configuration in the nano text editor so you can make adjustments as necessary.  These settings allow for detailed control over gameplay elements and server performance, tailoring the experience to both server administrator preferences and player needs.Some of the options available are listed below:

### Primary Configuration Options:

- **adminList**: A list of admin Steam IDs.
- **modList**: List of moderator Steam IDs. 
- **advertiseName**: The name displayed on the public server list if the `--advertise` option is used.  If it is not set, the World Name will be used in the multiplayer screen.
- **allowList**: A whitelist of player Steam IDs allowed to connect.  If something is set in here basically to log in you need to be in this list.
- **banList**: A list of banned player Steam IDs.
- **dayLength**: The length of a day in seconds.
- **disableTribeSpawns**: Set to `true` to prevent new tribe spawns.
- **globalTimeZone**: If `true`, uses a single time zone for all players.
- **maxPlayers**: The maximum number of players allowed to connect.
- **welcomeMessage**: Message displayed to players upon connection.
- **worldName**: The name of the world.  **NOTE** if you change the name of your world here, you also need to change it in the info.json file in the same directory, and run `./sapiens.sh config` again to pick up the new name.

### Game Overrides:

- **aiTribeMaxPopulation**: Maximum population for AI tribes.
- **allowedPlansPerFollower**: Number of plans a follower can execute concurrently.
- **compostBinMaxItemCount**: Maximum number of items a compost bin can hold.
- **fireWarmthRadius**: The radius around a fire that provides warmth.
- **hibernateTribeAfterClientDisconnectDelay**: Duration a tribe remains loaded after player disconnects.
- **maxTerrainSteepness**: Maximum terrain steepness allowed between hex centers.
- **populationLimitGlobalSoftCap**: Global soft cap on population, affecting birth rates.
- **rainAffectedCallbackLowChancePerSecond**: Chance per second of rain affecting certain objects.

## World Management Commands

Once you have an active world configured, below is a list of available commands for managing the world through the command line interface provided by the script. 

| `./sapiens.sh` *arg*              | Description                                                                                            |
|-----------------------------------|--------------------------------------------------------------------------------------------------------|
| `start`                           | Starts the active world in the background.                                                             |
| `console`                         | Opens the world's console. To exit without stopping the server, hold CTRL and type A D.                |
| `stop`                            | Stops the active world.  This does not cancel any autorestart schedule.                                |
| `hardstop`                        | Stops your world and cancels any autorestart schedule that is set.                                     |
| `restart`                         | Manually restarts the server. Useful if things are getting laggy.                                      |
| `autorestart [0-24]`              | Automatically restarts the world at the specified hour interval. Setting to 0 cancels the autorestart. |
| `upgrade`                         | Forces an upgrade of the Sapiens server executable from Steam ('start' does this automatically).       |
| `backup`                          | Stops the world and backs it up to the backup folder.                                                  |
| `config`                          | Selects and configures the active world. Runs initial installation if required.                        |
| `worldconfig`                     | Opens the active world's Lua configuration file (config.lua) for editing.                              |
| `info`                            | Shows information about the active world.                                                              |


## Minimal Installation Scripts

If you are just looking to get a working linuxServer with dependencies installed you can use the minimal script.  This just installs the executable to a running state, but no other scripts for managing it are provided, except a startworld.sh script to restart the server if it crashes.

```bash

chmod +x minstall.sh startworld.sh update.sh
./minstall.sh
```

### Configuration for Minimal Setup

You can create a new world after installation:

```bash
./linuxServer --new "Test World" --server-id "chillgenxer"
```

Update the `STEAM_UPDATE_SCRIPT` path in `minstall.sh` & `update.sh` to the correct location if moved.
Set up server and network configurations in `startworld.sh`, adjusting the parameters like `$WORLD_NAME`, `$SERVER_ID`, and network ports.

## Contribution and Support

Contributions, issues, and feature requests are welcome! For major changes, please open an issue first to discuss what you would like to change. Visit [GitHub issues](https://github.com/ChillGenXer/sapiens-server/issues) for requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
