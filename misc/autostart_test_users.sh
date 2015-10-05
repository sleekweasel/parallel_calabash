#!/bin/bash
# Invokes the autostart application, after resetting the Screen Sharing app and re-enabling automator permissions.

AUTOSTART=/Applications/autostart_test_users.app
if [ -d "${AUTOSTART}" ]; then
  echo Killing screen sharing and running ${AUTOSTART}
  killall "Screen Sharing"
  echo qwerty | sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "INSERT or REPLACE INTO access VALUES('kTCCServiceAccessibility','com.apple.ScriptEditor.id.autostart-test-users',0,1,0,NULL)"'
  open ${AUTOSTART}
else
  echo No ${AUTOSTART} found
fi
