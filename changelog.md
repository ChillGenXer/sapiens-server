##1.0.0##
- Updated enet log location and added sapservermgr.log
- Refactored code
- Checks Sapiens version on startup and upgrades if necessary.

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
