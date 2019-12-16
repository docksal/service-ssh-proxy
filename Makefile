-include env_make

ifeq ($(VERSION),)
    VERSION = dev
    LATEST_VERSION = $(VERSION)
endif

BUILD_TAG ?= $(VERSION)

REPO = docksal/ssh-proxy
NAME = docksal-ssh-proxy
DOCKER ?= docker
DOCKER_HOST_IP ?= 0.0.0.0
VOLUME ?= docksal_projects_ssh

.EXPORT_ALL_VARIABLES:

.PHONY: build exec test push shell run start stop logs debug clean release

build:
	$(DOCKER) build -t ${REPO}:${BUILD_TAG} .

test:
	NAME=${NAME} IMAGE=${REPO}:${BUILD_TAG} bats tests/test.bats

push:
	$(DOCKER) push ${REPO}:${BUILD_TAG}

exec:
	@$(DOCKER) exec ${NAME} ${CMD}

exec-it:
	@$(DOCKER) exec -it ${NAME} ${CMD}

shell:
	@$(DOCKER) exec -it ${NAME} sh

start-volume:
	$(DOCKER) volume create --name $(VOLUME)

start-container:
	$(DOCKER) run -d \
		--name=$(NAME) \
		--label "io.docksal.group=system" \
		--restart=always \
		-p "$(DOCKER_HOST_IP):2222":2222 \
		--mount type=volume,src=${VOLUME},dst=/ssh-proxy \
		--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
		${REPO}:${BUILD_TAG}

start: start-volume start-container

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
	@scripts/docker-push.sh

remove-volume:
	$(DOCKER) volume rm ${VOLUME} || true

remove-container:
	$(DOCKER) rm -f ${NAME} || true

clean: remove-container remove-volume

remake: stop remove-container build

remake-start: remake start

rebuild: stop clean build start

default: build
