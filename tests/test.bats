#!/usr/bin/env bats

setup () {
	make start
	_healthcheck_wait
}

# Debugging
teardown() {
	docker network disconnect drupal8_default docksal-ssh-proxy
	make clean
	rm -rf $HOME/.ssh/test_rsa || true

	echo "Status: $status"
	echo "Output:"
	echo "================================================================"
	for line in "${lines[@]}"; do
		echo $line
	done
	echo "================================================================"
}

# Checks container health status (if available)
# @param $1 container id/name
_healthcheck ()
{
	local health_status
	health_status=$(docker inspect --format='{{json .State.Health.Status}}' "$1" 2>/dev/null)

	# Wait for 5s then exit with 0 if a container does not have a health status property
	# Necessary for backward compatibility with images that do not support health checks
	if [[ $? != 0 ]]; then
	echo "Waiting 10s for container to start..."
	sleep 10
	return 0
	fi

	# If it does, check the status
	echo $health_status | grep '"healthy"' >/dev/null 2>&1
}

# Waits for containers to become healthy
_healthcheck_wait ()
{
	# Wait for cli to become ready by watching its health status
	local container_name="${NAME}"
	local delay=5
	local timeout=30
	local elapsed=0

	until _healthcheck "$container_name"; do
		echo "Waiting for $container_name to become ready..."
		sleep "$delay";

		# Give the container 30s to become ready
		elapsed=$((elapsed + delay))
		if ((elapsed > timeout)); then
				echo "$container_name heathcheck failed"
				exit 1
		fi
	done

	return 0
}

@test "${NAME} container is up and using the \"${IMAGE}\" image" {
	[[ ${SKIP} == 1 ]] && skip

	run docker ps --filter "name=${NAME}" --format "{{ .Image }}"
	[[ "$output" =~ "${IMAGE}" ]]
	unset output
}

@test "Adding New Project Key" {
	[[ $SKIP == 1 ]] && skip

	# Generate ssh-key
	ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/test_rsa
	KEY=$(cat $HOME/.ssh/test_rsa.pub)
	run docker exec ${NAME} proxyctl add-key drupal8 "${KEY}"
	[[ "${output}" =~ "Creating /ssh-proxy/drupal8/keys/" ]]
	[[ "${output}" =~ "Added key to" ]]
	unset output
}

@test "Adding New Project Key By Name" {
	[[ $SKIP == 1 ]] && skip

	# Generate ssh-key
	ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/test_rsa
	KEY=$(cat $HOME/.ssh/test_rsa.pub)

	### Tests ###
	run docker exec ${NAME} proxyctl add-key drupal8 "${KEY}" test-key
	[[ "${output}" =~ "Creating /ssh-proxy/drupal8/keys/test-key" ]]
	[[ "${output}" =~ "Added key to drupal8" ]]
	unset output
}

@test "Adding Duplicate Project Key" {
	[[ $SKIP == 1 ]] && skip

	# Generate ssh-key
	ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/test_rsa
	KEY=$(cat $HOME/.ssh/test_rsa.pub)
	docker exec ${NAME} proxyctl add-key drupal8 "${KEY}"

	### Tests ###
	run docker exec ${NAME} proxyctl add-key drupal8 "${KEY}"
	[[ "${output}" =~ "Key already exists" ]]
	unset output
}

@test "Removing Project Key" {
	[[ $SKIP == 1 ]] && skip

	# Generate ssh-key
	ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/test_rsa
	KEY=$(cat $HOME/.ssh/test_rsa.pub)
	docker exec ${NAME} proxyctl add-key drupal8 "${KEY}" test-key

	### Tests ###
	run docker exec ${NAME} proxyctl remove-key drupal8 test-key
	[[ "${output}" =~ "Removed key test-key from drupal8" ]]
	unset output
}

@test "List Keys" {
	[[ $SKIP == 1 ]] && skip

	# Generate ssh-key
	ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/test_rsa
	KEY=$(cat $HOME/.ssh/test_rsa.pub)
	docker exec ${NAME} proxyctl add-key drupal8 "${KEY}" test-key

	### Tests ###
	run docker exec ${NAME} proxyctl list-keys
	[[ "${output}" =~ "test-key: ${KEY}" ]]
	unset output
}

@test "List Projects" {
	[[ $SKIP == 1 ]] && skip

	### Tests ###
	run docker exec ${NAME} proxyctl list-projects
	[[ "${output}" =~ "- drupal8" ]]
	[[ "${output}" =~ "- drupal7" ]]
	unset output
}

@test "Connecting to drupal8" {
	[[ $SKIP == 1 ]] && skip

	# Generate ssh-key
	ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/test_rsa
	KEY=$(cat $HOME/.ssh/test_rsa.pub)
	docker exec ${NAME} proxyctl add-key drupal8 "${KEY}" test-key

	### Tests ###
	run ssh -i $HOME/.ssh/test_rsa -p 2222 drupal8@drupal8.docksal 'hostname'
	[[ "${output}" =~ "cli" ]]
	unset output
}

@test "Fail Connecting to drupal7" {
	[[ $SKIP == 1 ]] && skip

	# Generate ssh-key
	ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/test_rsa
	KEY=$(cat $HOME/.ssh/test_rsa.pub)
	docker exec ${NAME} proxyctl add-key drupal8 "${KEY}" test-key

	### Tests ###
	run ssh -oBatchMode=yes -i $HOME/.ssh/test_rsa -p 2222 drupal7@drupal7.docksal 'hostname'
	[[ "${output}" =~ "Permission denied (publickey,password)" ]]
	unset output
}
