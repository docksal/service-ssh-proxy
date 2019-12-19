#!/usr/bin/env bash

# check sshd process is running
ps | grep -v 'grep' | grep sshpiperd >/dev/null 2>&1 || exit 1

# check crond process is running
ps | grep -v 'grep' | grep crond >/dev/null 2>&1 || exit 1

exit 0
