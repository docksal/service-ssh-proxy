# SSH proxy Docker image for Docksal

Automated SSH proxy for Docksal.

Docksal SSH Proxy is proxy-like ware, and route connections by project
name to the appropriate `cli` container.

```
+---------+                        +---------------+  +------------+
|         |                        |               |  |            |
|   Bob   +-- ssh -l project1 --+  |             +-----> project1  |
|         |                     |  | SSH Proxy   | |  |            |
+---------+                     |  |             | |  +------------+
                                +------------->--+ |
+---------+                     |  |             | |  +------------+
|         |                     |  |             | |  |            |
|  Alice  +-- ssh -l project2 --+  |             +-----> project2  |
|         |                        |               |  |            |
+---------+                        +---------------+  +------------+


 Developers                         Docksal SSH Proxy   Project Network

```

This image(s) is part of the [Docksal](http://docksal.io) image library.

## Features

* Project name routing
* Global keys that should be added to all projects.
* Project specific keys for added security
* Automatic connecting to Docksal Projects

## Usage

Generating the Volume for persistent storage:

```
docker volume create docksal_projects_ssh
```

Start the proxy container:

```
docker run -d \
    --name=docksal-vhost-proxy \
    --label "io.docksal.group=system" \
    --restart=always \
    -p "${DOCKSAL_VHOST_PROXY_PORT_SSH:-2222}":2222 \
    --mount type=volume,src=docksal_projects_ssh,dst=/ssh-proxy \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    docksal/ssh-proxy
```

## Container configuration

The SSH Proxy reads routing settings from container labels. The following labels are used:

`io.docksal.project-root`

Used for filtering out only docksal related projects.

`io.docksal.virtual-host`

Used for filtering out only the containers that have this label.

`com.docker.compose.project`

Used for returning the project name. This is also used for the username when ssh-ing through the
proxy.

`com.docker.compose.service`

This is used for searching for the container marked as `cli` within a project.

## Logging and debugging

The following container environment variables can be used to enabled various logging options.

`SSH_PROXY_LOGLEVEL` - Follow values of syslog logging. Settings values between 0 and 7 (default 3)

Check logs with `docker logs docksal-ssh-proxy`.
