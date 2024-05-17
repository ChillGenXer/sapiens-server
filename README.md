Thanks for sharing your previous README.md. I'll incorporate the details from your scripts into a revised version of your README that reflects the current state of your project.

---

# Sapiens Linux Server Helper Scripts

This repository offers a comprehensive toolkit for the installation and management of the Sapiens Dedicated Server on Linux, specifically optimized for Ubuntu (23.10 or greater). These scripts simplify the process of running the server, performing updates, and managing server life cycles.

## Latest Version Compatibility

- **Last tested Sapiens Dedicated Server Version: 0.5.0.47**

## Prerequisites

The server should not be run as the root user for security reasons. Set up a non-root user with sudo privileges for server operations:

```bash
# Add user
sudo adduser sapserver

# Add user to sudo group
sudo usermod -aG sudo sapserver
```

## Installation

Clone the repository into a directory called `sapiens-server` in the home directory of the user that will run the server:

```bash
git clone https://github.com/ChillGenXer/sapiens-server.git
cd sapiens-server

# Make the install script executable
chmod +x install.sh

# Run the install script
./install.sh
```

**Important**: Before deleting any old `sapiens-server` folder, ensure to back up any important data from `world_backups` and `log_backups`.

## Configuration

After installation, configure your world settings in the `config.lua` file located at:

```
$HOME/.local/share/majicjungle/players/SERVER-ID/worlds/YOUR-WORLD-ID/config.lua
```

This file allows you to set public advertising and customize the server display name (`advertiseName`).

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
