# sapiens-server
Installation and management scripts for the Sapiens Dedicated Server on Ubuntu (Linux).<br>
**Last tested Sapiens Dedicated Server Version: 0.5.0.44**

This package assumes you have an **Ubuntu 23.10 or greater** installation ready and a user that the server will run under, and is setup with ``sudo`` access.  Please ensure you create a new user that will be used for the server to run on, **the install script will not run if installed as the root user!**  To set up a new user:

**``sudo adduser sapserver``**

or if you are creating the user as the root user:
**``adduser sapserver``**

Set a password for the new user.  Now, add the user to the sudo group (without the first ``sudo`` if you are installing as the ``root`` user:
**``sudo usermod -aG sudo sapserver``**

In this example "sapserver" is the user ID you will log into and run the server with.

## Installation

First thing is to clone these helper files to your server.  This set of scripts currently expects to run in the user home folder in a directory called "sapiens-server".  Log into Ubuntu with the username you will be using for the server.  From the **home folder** type:

**``git clone https://github.com/ChillGenXer/sapiens-server.git``**

Please note these scripts expect to run in a folder called "sapiens-server" in the home directory.  It will not work correctly if installed in another location.  As a best practice this user account should only be used for the sapiens server.  It will run in the background and you will be able to log out and not have to keep the console open.

Now navigate to the new directory:<br>

**``cd sapiens-server``**

Now we need to make the install script executable:<br>

**``chmod +x install.sh``**

Now run it:

**``./install.sh``**

Once the script has completed, let's edit our servers config.  We will find that here:

**``cd ~/.local/share/majicjungle/sapiens``**<br>
**``nano serverConfig.lua``**

There are various options that can be changed in here, the two main ones for this are "serverName" (this is seperate from your World name) and "advertise".  If you set ``advertise=true`` your server will show up in the Multiplayer select screen in Sapiens for other people to connect.  

**Please note** the install script is asking for these values but not currently writing them.  This will come soon.  Manually edit them with the instructions above for now.

Ok once you have changed the serverConfig.lua to your needs, save it and close nano. Let's go back to the helper scripts folder:

**``cd ~/sapiens-server``**

Your server is now ready to run!  From now on, when you log in you can change to the sapiens-server directory and you can use the sapiens.sh script:

## Commands

./sapiens.sh **start** - starts your world in the background.
./sapiens.sh **console** - Bring the running world's console. To exit without stopping the server hold CTRL and type A D.       
./sapiens.sh **stop** - stops your world.
./sapiens.sh **restart** - Basically a stop, wait, and then a start. Good to use if things are getting laggy.
./sapiens.sh **upgrade** - This will update you to the latest version of the Sapiens server."
./sapiens.sh **backup** - Stops the world and backs it up to the backup folder."
./sapiens.sh **autorestart [minutes]** - Automatically restart the world at the specified interval.  Set to 0 to disable.
