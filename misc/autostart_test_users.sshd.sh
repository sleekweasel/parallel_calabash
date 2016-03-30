#!/bin/bash

# Tweak sshd_config's port to match ordinality of .parallel_calabash.autostart
echo Home: $HOME
echo Config: ${0%/*}/../.parallel_calabash.autostart
date
date 1>&2

USERS=$( ruby -e "config = eval File.read('${0%/*}/../.parallel_calabash.autostart'); puts config[:USERS]" )
echo Users: $USERS
echo Me: $( whoami )
SSH_PORT=$( ruby -e "config = eval File.read('${0%/*}/../.parallel_calabash.autostart'); puts((config[:USERS].map{|w|w.split('@')[0]}.index(%x(whoami).chomp)||-1)+2201)" )
echo Starting on port $SSH_PORT
echo $SSH_PORT >$HOME/autostart_test_users.sshd.port
sed -E -i~ 's/^#?Port.*/Port '$SSH_PORT'/' $HOME/ssh/sshd_config

# Run sshd as non-daemon

/usr/sbin/sshd -D -f $HOME/ssh/sshd_config
