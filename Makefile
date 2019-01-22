-include env_make

VERSION ?= dev

REPO = docksal/ssh-proxy
NAME = docksal-ssh-proxy
DOCKER ?= fin docker
DOCKER_HOST ?= 0.0.0.0

.EXPORT_ALL_VARIABLES:

.PHONY: build exec test push shell run start stop logs debug clean release

build:
	$(DOCKER) build -t ${REPO}:${VERSION} .

test:
	IMAGE=${REPO}:${VERSION} bats tests/test.bats

push:
	$(DOCKER) push ${REPO}:${VERSION}

exec:
	@$(DOCKER) exec ${NAME} ${CMD}

exec-it:
	@$(DOCKER) exec -it ${NAME} ${CMD}

shell:
	@$(DOCKER) exec -it ${NAME} sh

start:
	$(DOCKER) run -d \
		--name=$(NAME) \
		--label "io.docksal.group=system" \
		--restart=always \
		-p "$(DOCKER_HOST):2222":2222 \
		--mount type=volume,src=docksal_ssh_agent,dst=/.ssh-agent,readonly \
		--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
		${REPO}:${VERSION}

start-stopped:
	$(DOCKER) start $(NAME)

stop:
	$(DOCKER) stop ${NAME} || true

restart: stop start-stopped

logs:
	$(DOCKER) logs ${NAME}

logs-follow:
	$(DOCKER) logs -f ${NAME}

debug: build start logs-follow

release:
	@scripts/release.sh

clean:
	$(DOCKER) rm -vf ${NAME} || true

remake: stop clean build

remake-start: remake start

default: build
