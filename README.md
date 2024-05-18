# Sapiens Linux Server Helper Scripts
- **Last tested Sapiens Dedicated Server Version: 0.5.0.47**

This repository offers a comprehensive command line interface for the installation and management of the Sapiens Dedicated Server on Linux, specifically optimized for Ubuntu (23.10 or greater). These scripts simplify the process of running the server, performing updates, and managing the server's life cycle.

## Compatibility Note

These scripts were developed and thoroughly tested on Ubuntu 23.10 and are designed to run in a Bash environment with `apt` as the package manager. While efforts have been made to ensure compatibility across different Linux distributions, the functionality may vary outside the tested environment. If you encounter issues on other distributions please report them. This will help me assess the feasibility of extending compatibility or provide specific workarounds.

Certainly! Tailoring the section to focus on optimizing the server operation within a user-specific context and considering how SteamCMD functions can make the instructions more relevant for users who may or may not want to set up a new account. Here's the revised section:

---

## Prerequisites

To optimize the performance and management of your Sapiens server, it is advisable to run the server within a dedicated user account. This setup takes advantage of how SteamCMD installs and manages the game's executable and related files within the `.local` directory of a user's home directory. While setting up a new user account is not mandatory, doing so can help maintain a clean and organized environment, especially useful for isolating the server from other system processes.  

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

It is best to start fresh and delete any previous version installed. As long as you use the same Linux username, your old world or worlds will be detected by these scripts.

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

## Configuration

Once you have a configured server
Edit the `config.lua` file to customize your server settings. This file can be edited using the `./sapiens.sh worldconfig` command, which opens the configuration in the default editor.

### Primary Configuration Options:

- **adminList**: A list of admin Steam IDs.
- **advertiseName**: The name displayed on the public server list if the `--advertise` option is used.
- **allowList**: A whitelist of player Steam IDs allowed to connect.
- **banList**: A list of banned player Steam IDs.
- **dayLength**: The length of a day in game ticks.
- **disableTribeSpawns**: Set to `true` to prevent new tribe spawns.
- **globalTimeZone**: If `true`, uses a single time zone for all players.
- **maxPlayers**: The maximum number of players allowed to connect.
- **modList**: List of mods enabled on the server.
- **welcomeMessage**: Message displayed to players upon connection.
- **worldName**: The name of the world.

### Advanced Configuration Options (Overrides):

- **aiTribeMaxPopulation**: Maximum population for AI tribes.
- **allowedPlansPerFollower**: Number of plans a follower can execute concurrently.
- **compostBinMaxItemCount**: Maximum number of items a compost bin can hold.
- **fireWarmthRadius**: The radius around a fire that provides warmth.
- **hibernateTribeAfterClientDisconnectDelay**: Duration in game ticks a tribe remains loaded after player disconnects.
- **maxTerrainSteepness**: Maximum terrain steepness allowed between hex centers.
- **populationLimitGlobalSoftCap**: Global soft cap on population, affecting birth rates.
- **rainAffectedCallbackLowChancePerSecond**: Chance per second of rain affecting certain objects.

These settings allow for detailed control over gameplay elements and server performance, tailoring the experience to both server administrator preferences and player needs.

## Commands

- `./sapiens.sh start`: Starts your world in the background.
- `./sapiens.sh console`: Accesses the running world's console. To exit, hold CTRL and type A D.
- `./sapiens.sh stop`: Stops your world.
- `./sapiens.sh hardstop`: Stops your world and cancels autorestart.
- `./sapiens.sh restart`: Restarts the server. Useful if performance lags.
- `./sapiens.sh upgrade`: Updates to the latest Sapiens server version.
- `./sapiens.sh backup`: Backs up the world to the specified backup folder.
- `./sapiens.sh autorestart [minutes]`: Sets an automatic restart interval. Set to 0 to disable.

`./install.sh`: Reconfigures or switches the active world.

## Minimal Installation Scripts

For a minimal setup with just the basics:

```bash


chmod +x minstall.sh startworld.sh update.sh
./minstall.sh
```

### Configuration for Minimal Setup

You must create a new world after installation:

```bash
./linuxServer --new "Test World" --server-id "chillgenxer"
```

Update the `STEAM_UPDATE_SCRIPT` path in `minstall.sh` & `update.sh` to the correct location if moved.

Set up server and network configurations in `startworld.sh`, adjusting the parameters like `$WORLD_NAME`, `$SERVER_ID`, and network ports.

## Contribution and Support

Contributions, issues, and feature requests are welcome! For major changes, please open an issue first to discuss what you would like to change. Visit [GitHub issues](https://github.com/ChillGenXer/sapiens-server/issues) for requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
