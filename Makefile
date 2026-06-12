init: temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env

temp/certs/ca.key temp/certs/ca.crt temp/certs/ssh_key temp/certs/ssh_key.pub temp/secrets.sh temp/secrets.env:
	@ ./scripts/init.sh

install:
	@ . ./scripts/detect-runtime.sh; \
	if [ "$$IS_PODMAN" = "true" ]; then export SKIP_CILIUM="true"; fi; \
	kind get kubeconfig --name cfk8s > temp/kubeconfig; \
	if ! command -v helmfile &> /dev/null; then \
		echo "helmfile not found, using $$CONTAINER_RUNTIME to run helmfile"; \
		$$CONTAINER_RUNTIME run --rm --net=host --env-file temp/secrets.env \
			--env INSTALL_OPTIONAL_COMPONENTS \
			--env CILIUM_EXTRA_VALUES \
			--env SKIP_CILIUM \
			-v "$$PWD/temp/certs:/certs" -v "$$PWD/temp/kubeconfig:/helm/.kube/config:ro" -v "$$PWD:/wd" --workdir /wd ghcr.io/helmfile/helmfile:v$(HELMFILE_VERSION) helmfile sync; \
	else \
		echo "helmfile found, using local helmfile"; \
		source temp/secrets.sh; \
		CILIUM_EXTRA_VALUES="$$CILIUM_EXTRA_VALUES" SKIP_CILIUM="$$SKIP_CILIUM" helmfile sync --kubeconfig temp/kubeconfig; \
	fi

login:
	@ . temp/secrets.sh; \
	curl --silent --show-error --fail --insecure --retry 9 --retry-delay 5 --retry-all-errors --output /dev/null "https://api.cf.127-0-0-1.nip.io/v2/info"; \
	echo "API is ready. Logging in..."; \
	cf login -a https://api.cf.127-0-0-1.nip.io -u ccadmin -p "$$CC_ADMIN_PASSWORD" --skip-ssl-validation

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

.PHONY: install login create-kind delete-kind up down create-org bootstrap bootstrap-complete
