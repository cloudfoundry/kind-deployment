LOCAL = true
TARGET_ARCH ?= $(if $(filter true,$(LOCAL)),$(shell go env GOARCH),amd64)

init: temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh

temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh:
	@ ./scripts/init.sh

install:
	@ . temp/secrets.sh; \
	helmfile sync

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
	@ ./scripts/upload_buildpacks_complete.sh

up: create-kind init install

down: delete-kind

PHONY: install login create-kind delete-kind up down create-org bootstrap bootstrap-complete
