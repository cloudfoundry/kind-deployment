LOCAL = true
TARGET_ARCH ?= $(if $(filter true,$(LOCAL)),$(shell go env GOARCH),amd64)
# renovate: dataSource=github-releases depName=helmfile/helmfile
HELMFILE_VERSION ?= "1.5.0"

# Build all images for the local architecture (arm64 on Apple Silicon, amd64 elsewhere).
# This ensures Go binaries like storage-cli are native – not run under Rosetta,
# which causes 'taggedPointerPack' panics with high memory addresses.
build:
	@ . ./scripts/detect-runtime.sh; \
	if [ "$$CONTAINER_RUNTIME" = "podman" ]; then \
		echo "Building with Podman is not yet supported via docker-bake.hcl."; \
		echo "Use 'podman build' manually with the Dockerfiles in releases/."; \
		exit 1; \
	fi; \
	docker buildx bake --file docker-bake.hcl --set "*.platform=linux/$(TARGET_ARCH)" $(BAKE_TARGETS)

init: temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env

temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env:
	@ ./scripts/init.sh

install:
	kind get kubeconfig --name cfk8s > temp/kubeconfig
	@ . ./scripts/detect-runtime.sh; \
	if [ "$$IS_PODMAN" = "true" ]; then ./scripts/setup-podman-vm.sh; fi; \
	$$CONTAINER_RUNTIME run --rm --net=host --env-file temp/secrets.env \
		--env INSTALL_OPTIONAL_COMPONENTS \
		-v "$$PWD/temp/certs:/certs" -v "$$PWD/temp/kubeconfig:/helm/.kube/config:ro" -v "$$PWD:/wd" --workdir /wd ghcr.io/helmfile/helmfile:v$(HELMFILE_VERSION) helmfile sync

login:
	@ . temp/secrets.sh; \
	cf login -a https://api.127-0-0-1.nip.io -u ccadmin -p "$$CC_ADMIN_PASSWORD" --skip-ssl-validation

create-kind:
	@ ./scripts/create-kind.sh

delete-kind:
	@ ./scripts/delete-kind.sh

create-org:
	cf create-org test
	cf create-space -o test test
	cf target -o test -s test
	@ ./scripts/set_feature_flags.sh

bootstrap: create-org
	@ ./scripts/upload_buildpacks.sh

bootstrap-complete: create-org
	@ ALL_BUILDPACKS=true ./scripts/upload_buildpacks.sh

up: create-kind init install

down: delete-kind
	@ rm -rf temp

PHONY: install login create-kind delete-kind up down create-org bootstrap bootstrap-complete
