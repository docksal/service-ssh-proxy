#!/usr/bin/env bats

# Debugging
teardown() {
        echo
        echo "Output:"
        echo "================================================================"
        echo "${output}"
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
        _healthcheck_wait

        run docker ps --filter "name=${NAME}" --format "{{ .Image }}"
        [[ "$output" =~ "${IMAGE}" ]]
        unset output
}

