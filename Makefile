LOCAL = true
TARGET_ARCH ?= $(if $(filter true,$(LOCAL)),$(shell go env GOARCH),amd64)
# renovate: dataSource=github-releases depName=helmfile/helmfile
HELMFILE_VERSION ?= v1.2.3

init: temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.env

temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.env:
	@ ./scripts/init.sh

install:
	kind get kubeconfig --name cfk8s > temp/kubeconfig
	docker run --rm --net=host --env-file temp/secrets.env -v "$$PWD/temp/kubeconfig:/helm/.kube/config:ro" -v "$$PWD:/wd" --workdir /wd ghcr.io/helmfile/helmfile:$(HELMFILE_VERSION) helmfile sync

login:
	@ . temp/secrets.env; \
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

check-changes:
	@ CURRENT_COMMIT=$$(git rev-parse HEAD); \
	CURRENT_TEMP_HASH=$$(find temp -type f -print0 | sort -z | xargs -0 cat | md5 || echo "no-temp"); \
	if [ -f .last-run-state ]; then \
		LAST_COMMIT=$$(grep "^COMMIT=" .last-run-state | cut -d= -f2); \
		LAST_TEMP_HASH=$$(grep "^TEMP_HASH=" .last-run-state | cut -d= -f2); \
		if [ "$$CURRENT_COMMIT" != "$$LAST_COMMIT" ] || [ "$$CURRENT_TEMP_HASH" != "$$LAST_TEMP_HASH" ]; then \
			echo "⚠️ Local changes detected, please run make down to ensure a clean state"; \
			exit 1; \
		fi; \
	fi

save-state:
	@ CURRENT_COMMIT=$$(git rev-parse HEAD); \
	CURRENT_TEMP_HASH=$$(find temp -type f -print0 | sort -z | xargs -0 cat | md5 || echo "no-temp"); \
	echo "COMMIT=$$CURRENT_COMMIT" > .last-run-state; \
	echo "TEMP_HASH=$$CURRENT_TEMP_HASH" >> .last-run-state

up: check-changes create-kind init install save-state

down: delete-kind
	@ rm .last-run-state

PHONY: install login create-kind delete-kind up down create-org bootstrap bootstrap-complete check-changes save-state
