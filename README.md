# sapiens-server
Some helpful scripts for running a Sapiens dedicated server on Linux.

This package assumes you have an Ubuntu 23.10 installation ready and a user that the server will run under setup which has sudo access.  

## Installation

First thing is to clone these helper files to your server.  Log into Ubuntu with the username you will be using for the server and type:

``git clone https://github.com/ChillGenXer/sapiens-server.git``

Now navigate to the new directory:

``cd sapiens-server``

Now we need to make the install script executable:
``chmod +x install.sh``

Now run it:

``./install.sh``

Answer any of the prompts affirmatively.

Once this is completed you should now have the sapiens server installed in your home .local directory. Navigate there:

``cd ~/.local/share/Steam/steamcmd/sapiens``

Now we will start it for the first time and set up the actual world folders.  Before we do that you can run the help command at this point to see what options are available:

``./linuxServer --help``

So you can see you have options to load a world, change ports, a few other things.  For now we are going to simply start the server and create our world using the ``new`` command.  You can change the name in quotes to what you like, but remember it exactly - we are going to need it later.

``./linuxServer --new "My New World"``

If you've done everything correctly up to this point, you should see the server start up.  You can type in "stop" and enter at this point because we have a little more setup to do to make things a bit more convenient, but you do need to run it once for all the directories to get created.

Ok now let's edit our servers config.  We will find that here:

``cd ~/.local/share/majicjungle/sapiens``
``nano serverConfig.lua``

There are various options that can be changed in here, the two main ones for this are "serverName" (this is seperate from your World name) and "advertise".  If you advertise your server will show up in the Multiplayer select screen in Sapiens for other people to connect.

Ok once you have changed the serverConfig.lua to your needs, save it and close nano. Let's go back to the helper scripts folder:

``cd ~/sapiens-server``

We are now going to update our config.sh file to put in the relevant directories and stuff so we never have to deal with them again.  The instructions in the file should hopefully be sufficent to be able to set it correctly.

``nano config.sh``

Your server is now ready to run.  From now on, when you log in you can change to the sapiens-server directory and you can use the command script:


**./sapiens.sh start** - starts your server in a screen session so it is running in the background.<br>
**./sapiens.sh stop** - stops your server running in the background.<br>
**./sapiens.sh restart** - Basically a stop, wait, and then a start.  Good to bounce the server if things are getting laggy.<br>
**./sapiens.sh upgrade** - This will run the Steam upgrade script and either update or refresh the Sapiens server executable.<br>
**./sapiens.sh backup** - Backs up the world to the designated backup folder.<br>
**./sapiens.sh console** - When a server is running in the background use this command to bring up the server console.  To exit the console without stopping the server hold CTRL and type A D.<br>

