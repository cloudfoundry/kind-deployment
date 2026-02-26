LOCAL = true
TARGET_ARCH ?= $(if $(filter true,$(LOCAL)),$(shell go env GOARCH),amd64)
IMAGE ?= cf-kind-deployment:latest
DOCKER_SOCKET ?= $(shell docker context inspect --format '{{.Endpoints.docker.Host}}' | sed 's|unix://||')
TTY_FLAG := $(shell [ -t 0 ] && echo "-it" || echo "-i")

# Common docker run options
run_opts = --rm $(TTY_FLAG) \
	--network host \
	-v $(DOCKER_SOCKET):/var/run/docker.sock \
	-v "$$PWD/temp:/workspace/temp" \
	-e ENABLE_TCP_ROUTING \
	-e ENABLE_NFS_VOLUME \
	-e ENABLE_POLICY_SUPPORT \
	-e ENABLE_LOGGREGATOR \
	-e DISABLE_CACHE

# Container run command
run = docker run $(run_opts) $(IMAGE)

# Default targets (container-based)
up: _build-installer-quiet
	$(run) "make _create-kind _init _install"

down: _build-installer-quiet
	$(run) "make _delete-kind"
	rm -rf temp

login:
	@ . ./temp/secrets.sh; \
	cf login -a https://api.127-0-0-1.nip.io -u ccadmin -p "$$CC_ADMIN_PASSWORD" --skip-ssl-validation

bootstrap: _build-installer-quiet
	$(run) "make login _bootstrap"

bootstrap-complete: _build-installer-quiet
	$(run) "make login _bootstrap-complete"

shell: _build-installer-quiet
	docker run $(run_opts) -v "$$PWD:/workspace" $(IMAGE) "bash"

# Build the installer container (verbose)
build-installer:
	docker build -t $(IMAGE) .

# Build the installer container (quiet)
_build-installer-quiet:
	@docker build -q -t $(IMAGE) . > /dev/null

# Internal targets (run inside container or on host with tools installed)
_init: temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env

temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env:
	@ ./scripts/init.sh

_install:
	kind get kubeconfig --name cfk8s > temp/kubeconfig
	@ . ./temp/secrets.sh && KUBECONFIG=temp/kubeconfig helmfile sync

_create-kind:
	@ ./scripts/create-kind.sh

_delete-kind:
	@ ./scripts/delete-kind.sh

_create-org:
	cf create-org test
	cf create-space -o test test
	cf target -o test -s test
	@ ./scripts/set_feature_flags.sh

_bootstrap: _create-org
	@ ./scripts/upload_buildpacks.sh

_bootstrap-complete: _create-org
	@ ALL_BUILDPACKS=true ./scripts/upload_buildpacks.sh

.PHONY: up down login bootstrap bootstrap-complete shell build-installer
.PHONY: _init _install _create-kind _delete-kind _create-org _bootstrap _bootstrap-complete _build-installer-quiet
