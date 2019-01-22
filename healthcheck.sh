#!/usr/bin/env bash

# supervisor services are running
if [[ -f /run/supervisord.pid ]]; then
	supervisorctl status sshpiperd | grep RUNNING >/dev/null || exit 1
	supervisorctl status crond | grep RUNNING >/dev/null || exit 1

	exit 0
fi

exit 1
