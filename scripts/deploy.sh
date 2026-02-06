#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/../temp"
CERTS_DIR="$DEPLOY_DIR/certs"

# renovate: depName=cloudfoundry/k8s-garden-client
K8S_REP_VERSION="0.2.2"
# renovate: depName=cloudfoundry/k8s-policy-agent
POLICY_AGENT_VERSION="0.1.0"
# renovate: depName=cloudfoundry/cflinuxfs4-release image=ghcr.io/cloudfoundry/k8s/cflinuxfs4
CFLINUXFS4_VERSION="1.304.0"

source "$DEPLOY_DIR/secrets.sh"

kubectl create namespace cf-workloads --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap ca --namespace default --from-file "$CERTS_DIR/ca.crt" --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap trusted-system-certs --namespace cf-workloads --from-file=trusted-ca-1.crt="$CERTS_DIR/ca.crt" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic instance-identity --namespace default --from-file=tls.crt="$CERTS_DIR/ca.crt" --from-file=tls.key="$CERTS_DIR/ca.key" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic root-ca --namespace default --from-file=tls.crt="$CERTS_DIR/ca.crt" --from-file=tls.key="$CERTS_DIR/ca.key" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic root-ca --namespace cert-manager --from-file=tls.crt="$CERTS_DIR/ca.crt" --from-file=tls.key="$CERTS_DIR/ca.key" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --hide-notes --install cert-manager oci://quay.io/jetstack/charts/cert-manager:v1.19.2 --namespace cert-manager --set crds.enabled=true --wait

kubectl apply --filename assets/network-policy.yaml
kubectl apply --filename assets/cluster-issuer.yaml
kubectl apply --filename assets/nats-certificate.yaml
kubectl apply --filename assets/postgres-tls.yaml

helm upgrade --hide-notes --install nats --repo https://nats-io.github.io/k8s/helm/charts nats --values assets/values/nats.yaml

kubectl apply --server-side --filename assets/gateway-api.yaml

helm upgrade --hide-notes --install istio-base --repo https://istio-release.storage.googleapis.com/charts base --version 1.28.3 --namespace istio-system --values assets/values/istio-base.yaml
kubectl delete validatingwebhookconfiguration istio-validator-istio-system --ignore-not-found=true
helm upgrade --hide-notes --install istiod --repo https://istio-release.storage.googleapis.com/charts istiod --version 1.28.3 --namespace istio-system --values assets/values/istiod.yaml

kubectl apply --filename assets/gateway.yaml

helm upgrade --hide-notes --install postgresql --repo https://charts.bitnami.com/bitnami postgresql --set auth.password=$DB_PASSWORD --values assets/values/postgresql.yaml

helm upgrade -i minio oci://docker.io/bitnamicharts/minio --set rootUser=rootuser,rootPassword=rootpass123 --set console.enabled=false --set resourcesPreset=small --set auth.rootPassword=$BLOBSTORE_PASSWORD --set image.repository=bitnamilegacy/minio --set global.security.allowInsecureImages=true --hide-notes

kubectl rollout status statefulset nats
kubectl rollout status statefulset postgresql
kubectl rollout status deployment minio

## end of mandatory dependencies, start of CF components

## components without dependencies
helm upgrade --install uaa releases/uaa/helm --set ccAdminPassword=$CC_ADMIN_PASSWORD --set dbPassword=$DB_PASSWORD --set oauthClientsSecret=$OAUTH_CLIENTS_SECRET --set uaaAdminSecret=$UAA_ADMIN_SECRET --wait # no dependencies
helm upgrade --install loggregator-agent releases/loggregator-agent/helm --set "syslogBindingCache.enabled=true" --set "forwarderAgent.enabled=true" # no dependencies
helm upgrade --install loggregator releases/loggregator/helm --set oauthClientsSecret=$OAUTH_CLIENTS_SECRET # no dependencies, optional component

kubectl rollout status deployment forwarder-agent

## depending on forwarder-agent (loggregator-agent)
helm upgrade --install routing releases/routing/helm # connects to forwarder-agent (loggregator-agent), does not exit if it is missing
helm upgrade --install locket releases/diego/helm --set dbPassword=$DB_PASSWORD --set oauthClientsSecret=$OAUTH_CLIENTS_SECRET --set "locket.enabled=true" --wait # depends on forwarder-agent (loggregator-agent), does not become ready without it
helm upgrade --install diego releases/diego/helm --set dbPassword=$DB_PASSWORD --set diegoSSHCredentials=$DIEGO_SSH_CREDENTIALS --set oauthClientsSecret=$OAUTH_CLIENTS_SECRET --set-file sshProxyHostKey="$CERTS_DIR/ssh_key" --set "auctioneer.enabled=true" --set "bbs.enabled=true" --set "fileserver.enabled=true" --set "sshProxy.enabled=true" # depends on forwarder-agent (loggregator-agent), does not become ready without it

kubectl rollout status deployment uaa

## depending on uaa
helm upgrade --install log-cache releases/log-cache/helm # depends on uaa (uaa), does not become ready without it
helm upgrade --install credhub releases/credhub/helm --set dbPassword=$DB_PASSWORD # depends on uaa (uaa), does not become ready without it

kubectl rollout status deployment auctioneer
kubectl rollout status deployment bbs
kubectl rollout status deployment locket
kubectl rollout status deployment file-server
kubectl rollout status deployment credhub

## depending on diego
helm upgrade --install api releases/capi/helm --set cloudController.blobstore.password=$BLOBSTORE_PASSWORD --set dbPassword=$DB_PASSWORD --set oauthClientsSecret=$OAUTH_CLIENTS_SECRET --set cloudController.sshProxyKeyFingerprint=$SSH_PROXY_KEY_FINGERPRINT --set "cloudController.enabled=true" --wait # depends on bbs, locket, does not become ready without them
helm upgrade --install k8s-rep oci://ghcr.io/cloudfoundry/helm/k8s-rep:$K8S_REP_VERSION --set-file caCertificate="$CERTS_DIR/ca.crt" --set "stacks.cflinuxfs4=ghcr.io/cloudfoundry/k8s/cflinuxfs4:$CFLINUXFS4_VERSION" # depends on bbs and locket does not become ready without them

kubectl rollout status deployment cc-deployment-updater
kubectl rollout status deployment cc-uploader
kubectl rollout status deployment cc-worker
kubectl rollout status deployment cc-worker-clock
kubectl rollout status deployment cloud-controller

## depending on capi
helm upgrade --install tps-watcher releases/capi/helm --set "tpsWatcher.enabled=true" # depends on bbs, cc, locket does not become ready without them
helm upgrade --install route-emitter releases/diego/helm --set "routeEmitter.enabled=true" --set "routeEmitter.enableInternalEmitter=true" # depends on bbs and locket does not become ready without them
helm upgrade --install cf-networking releases/cf-networking/helm --set policyServer.dbPassword=$DB_PASSWORD --set policyServer.oauthClientsSecret=$OAUTH_CLIENTS_SECRET # depends on cc, uaa, locket, forwarder-agent (loggregator-agent), does not become ready without them
helm upgrade --install policy-agent oci://ghcr.io/cloudfoundry/helm/policy-agent:$POLICY_AGENT_VERSION # depends on policy-server (cf-networking), does not exit if it is missing

kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' | grep -q "apps.internal:53" || {
  echo "Patching CoreDNS to forward apps.internal to bosh-dns"
  BOSH_DNS_IP=$(kubectl get svc bosh-dns -n default -o jsonpath='{.spec.clusterIP}')
  COREFILE=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')
  printf '%s\n\n%s' "apps.internal:53 {
    errors
    forward . ${BOSH_DNS_IP}
}" "$COREFILE" | kubectl create configmap coredns -n kube-system --from-file=Corefile=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
  kubectl rollout restart deployment coredns -n kube-system
}

kubectl rollout status deployment policy-server
kubectl rollout status deployment policy-agent
kubectl rollout status deployment bosh-dns
kubectl rollout status deployment service-discovery-controller

kubectl rollout status daemonset k8s-rep

echo "All deployments and daemonsets are successfully rolled out."
