DEFAULT_CLUSTER_DOMAIN := 127-0-0-1.nip.io
CLUSTER_DOMAIN ?= $(DEFAULT_CLUSTER_DOMAIN)
LOCAL_DEPLOYMENT = $(if $(filter $(DEFAULT_CLUSTER_DOMAIN),$(CLUSTER_DOMAIN)),true,false)

init: temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env

temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env:
	@ ./scripts/init.sh $(CLUSTER_DOMAIN)

install:
	@ LOCAL_DEPLOYMENT=$(LOCAL_DEPLOYMENT) ./scripts/install.sh $(CLUSTER_DOMAIN)

login:
	@ . temp/secrets.sh; \
	curl --silent --show-error --fail --insecure --retry 9 --retry-delay 5 --retry-all-errors --output /dev/null "https://api.cf.$(CLUSTER_DOMAIN)/v3/info"; \
	echo "API is ready. Logging in..."; \
	cf login -a https://api.cf.$(CLUSTER_DOMAIN) -u ccadmin -p "$$CC_ADMIN_PASSWORD" --skip-ssl-validation

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

smoke:
	@ ./scripts/smoke.sh

cats:
	@ ./scripts/cats.sh

.PHONY: install login create-kind delete-kind up down create-org bootstrap bootstrap-complete smoke cats
