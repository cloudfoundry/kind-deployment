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
	@ ALL_BUILDPACKS=true ./scripts/upload_buildpacks.sh

up: create-kind init install

down: delete-kind

status:
	@ echo "===== KIND CLUSTER STATUS ====="
	@ kind get clusters 2>/dev/null || echo "No kind clusters running"
	@ echo ""
	@ echo "===== KUBERNETES NODES ====="
	@ kubectl get nodes 2>/dev/null || echo "Cluster not accessible"
	@ echo ""
	@ echo "===== PODS BY NAMESPACE ====="
	@ kubectl get pods -A 2>/dev/null || echo "Cluster not accessible"
	@ echo ""
	@ echo "===== SERVICES ====="
	@ kubectl get svc -A 2>/dev/null || echo "Cluster not accessible"

logs:
	@ echo "===== CLOUD CONTROLLER LOGS ====="
	@ kubectl logs -l app.kubernetes.io/name=cloud-controller --all-containers=true --tail=50 2>/dev/null || echo "Cloud Controller not found"
	@ echo ""
	@ echo "===== DIEGO LOGS ====="
	@ kubectl logs -l app.kubernetes.io/name=diego --tail=50 2>/dev/null || echo "Diego not found"
	@ echo ""
	@ echo "===== UAA LOGS ====="
	@ kubectl logs -l app.kubernetes.io/name=uaa --tail=50 2>/dev/null || echo "UAA not found"
	@ echo ""
	@ echo "===== ROUTER LOGS ====="
	@ kubectl logs -l app.kubernetes.io/name=gorouter --tail=50 2>/dev/null || echo "Router not found"

clean:
	@ echo "Cleaning up kind cluster and temporary files..."
	@ make delete-kind 2>/dev/null || true
	@ rm -rf temp/
	@ echo "Cleanup complete"

.PHONY: install login create-kind delete-kind up down create-org bootstrap bootstrap-complete init status logs clean
