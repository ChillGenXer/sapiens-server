#Change Log#
##1.0.7##
- Removed Build ID check from update

##1.0.6##
- Updated incorrect selection for log reporting on active world summary.

##1.0.5##
- Got rid of that annoying steamupdate.txt file

##1.0.4##
- Fixed condition when the linuxServer is not installed to query for version number.

##1.0.3##
- Correct steamcmd config file regression error.

##1.0.1-1.0.2##
- Minor documentation corrections and turned off debugging in constants.sh

##1.0.0##
- Added a "minimal" setup to just install dependencies.
- Updated enet log location so it is archived properly.
- Added a logging function and much more extensive application logging, including a debug flag in constants.
- Streamlined installation flow.  Removed "install.sh" and instead invoke with "./sapiens.sh config"
- Made server stop detection more robust.
- Checks Sapiens version whenever the world starts up and upgrades if necessary.
- Added a "./sapiens.sh info" option to show details about the currently active world.
- Added option to open game's lua config file for the world for editing.
- Refactored code for maintainability.
- Changed autorestart units to hours.
- Added message of how to exit console without exiting.

##0.4.1## - 2024-05-05
- Made bug reporting options configurable.
- Fixed placeholder descriptions for log_backups and world_backups.

##0.4.0##
- Started change log
- Cleaned up a bit of the install flow.
- Added ability to back up log files, automatically whenever the server starts or manual.
- Added ability to configure server advertising
- Updated all scripts to use ``#!/usr/bin/env bash`` to make them a little more portable.
- Tightened up the error checking a bit in start.sh
- Added server autorestart functionality, ./sapiens.sh autorestart [minutes].
