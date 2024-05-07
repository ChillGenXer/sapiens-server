# Sapiens Server Manager
Installation and management scripts for the Sapiens Dedicated Server on Ubuntu (Linux).<br>
**Last tested Sapiens Dedicated Server Version: 0.5.0.45**

This package assumes you have an **Ubuntu 23.10 or greater** installation ready and a user that the server will run under, and is setup with ``sudo`` access.  Please ensure you create a new user that will be used for the server to run on, **the install script will not run if installed as the root user!**  To set up a new user:

**``sudo adduser sapserver``**

or if you are creating the user as the root user:<br>
**``adduser sapserver``**

Set a password for the new user.  Now, add the user to the sudo group (without the first ``sudo`` if you are installing as the ``root`` user:<br>
**``sudo usermod -aG sudo sapserver``**

or if you are doing this as root:<br>
**``sudo usermod -aG sudo sapserver``**

In this example "sapserver" is the user ID you will log into and run the server with.

## Installation

If you have previous versions it is safe to remove the old folder and scripts before cloning the repository.  The one point to make here is that before you delete an old sapiens-server folder **make sure you move any backups you want to keep from world_backups and log_backup subfolders!**  The script will generate everything it needs when you run install.  If you have multiple worlds created you can run ./install.sh again to reconfigure the scripts to use a different world.

First thing is to clone these helper files to your server.  This set of scripts currently expects to run in the user home folder in a directory called "sapiens-server".  Log into Ubuntu with the username you will be using for the server.  From the **home folder** type:

**``git clone https://github.com/ChillGenXer/sapiens-server.git``**

Please note these scripts expect to run in a folder called "sapiens-server" in the home directory.  It will not work correctly if installed in another location.  As a best practice this user account should only be used for the sapiens server.  It will run in the background and you will be able to log out and not have to keep the console open.

Now navigate to the new directory:<br>

**``cd sapiens-server``**

Now we need to make the install script executable:<br>

**``chmod +x install.sh``**

Now run it:

**``./install.sh``**

Once the script has completed, you can edit your world config.  We will find that here:

nano ``$HOME/.local/share/majicjungle/players/SERVER-ID/worlds/YOUR-WORLD-ID/config.lua``

There are various options that can be changed in here, and the config file is pretty well documented. Of note is you can set public advertising of your server by running the install.sh script, however in the config file above you can change the ``advertiseName`` to change the text that actually shows up.  If you only use the install.sh script it will use the **World Name** by default.

Ok once you have changed the config.lua to your needs, save it and close nano. Let's go back to the helper scripts folder:

**``cd ~/sapiens-server``**

Your server is now ready to run!  From now on, when you log in you can change to the sapiens-server directory and you can use the sapiens.sh script.  If you ever want to change any of the options, just run ./install.sh again.

## Commands

./sapiens.sh **start** - starts your world in the background.
./sapiens.sh **console** - Bring the running world's console. To exit without stopping the server hold CTRL and type A D.       
./sapiens.sh **stop** - stops your world.
./sapiens.sh **hardstop** - Stops your world and cancels autorestart.
./sapiens.sh **restart** - Basically a stop, wait, and then a start. Good to use if things are getting laggy.
./sapiens.sh **upgrade** - This will update you to the latest version of the Sapiens server."
./sapiens.sh **backup** - Stops the world and backs it up to the backup folder."
./sapiens.sh **autorestart [minutes]** - Automatically restart the world at the specified interval.  Set to 0 to disable.

./install.sh - Allows for reconfiguration or switching of the active world you are running.
