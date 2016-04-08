#!/bin/bash

# Reboot if the default keychain is not login

echo Home: $HOME
echo Config: ${0%/*}/../.parallel_calabash.autostart
date
date 1>&2

PASSWORD=$( ruby -e "config = eval File.read('${0%/*}/../.parallel_calabash.autostart'); puts config[:PASSWORD]" )
echo Password: $PASSWORD
KEYCHAIN=$(security default)
echo Default keychain: $KEYCHAIN
case $KEYCHAIN in
  *login*) echo We like the login keychain. ;;
  *) echo We want the login keychain. Resetting it now.
     security default -s login.keychain
     KEYCHAIN=$(security default)
     case $KEYCHAIN in
       *login*) echo We set the login keychain. Rebooting now.
                echo $PASSWORD | sudo -S shutdown -r now Reboot with default keychain set to login.keychain
       ;;
       *) echo We failed to set the login keychain. Fail.
          osascript -e 'tell app "System Events" to display dialog "$0 failed to set the default keychain to login."'
     esac
esac
