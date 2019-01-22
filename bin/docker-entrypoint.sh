#!/usr/bin/env bash

set -e # Abort if anything fails

# Connect networks
/usr/local/bin/proxyctl networks

# Service mode
if [[ "$1" == "supervisord" ]]; then
	# Generate config files from templates

	exec supervisord -c /etc/supervisord.conf
# Command mode
else
	exec "$@"
fi