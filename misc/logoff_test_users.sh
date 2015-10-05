#!/bin/bash
# Runs killall over all the test users.

CONFIG_FILE="${HOME}/.parallel_calabash.autostart"
users=$(ruby -le "puts eval(File.read('$CONFIG_FILE'))[:USERS]")
if [ -z "$users" ] ; then
    echo "No users found to log out"
else
    for i in $users ; do
        echo logging out... $i
        ssh ${i}@localhost "osascript -e 'tell application \"System Events\"' -e 'log out' -e 'delay 3' -e 'keystroke return' -e end" &
    done
    wait
fi
