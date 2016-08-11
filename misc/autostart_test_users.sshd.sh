#!/bin/bash

# Run with port configured by setup_ios_host reported in .port file. (Originally tweaked by this script)
echo Home: $HOME
echo Config: ${0%/*}/../.parallel_calabash.autostart
date
date 1>&2

SSHD_CONFIG=$HOME/ssh/sshd_config
SSH_PORT=$( perl -nle '/Port ([0-9][0-9]*)/ && print $1' $SSHD_CONFIG )
echo Found $SSH_PORT in $SSHD_CONFIG
echo $SSH_PORT >$HOME/autostart_test_users.sshd.port

# Run sshd as non-daemon

/usr/sbin/sshd -D -f $SSHD_CONFIG
