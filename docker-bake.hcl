variable "REGISTRY_PREFIX" {
  default = ""
}

group "all" {
  targets = ["routing", "cf-networking", "capi", "diego", "loggregator", "loggregator-agent", "log-cache", "fileserver", "bosh-dns", "uaa", "cflinuxfs4", "misc"]
}

group "default" {
  targets = ["all"]
}

variable "ROUTING_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/routing-release
  default = "0.362.0"
}

target "routing" {
  dockerfile = "releases/routing/${component}.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}${component}:latest", "${REGISTRY_PREFIX}${component}:${ROUTING_RELEASE_VERSION}"]
  name = component
  
  matrix = {
    "component" = [ "gorouter", "route-registrar" ]
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/routing-release.git#v${ROUTING_RELEASE_VERSION}:src"
    "files" = "releases/routing/files"
  }
}

variable "CF_NETWORKING_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/cf-networking-release
  default = "3.98.0"
}

target "cf-networking" {
  dockerfile = "releases/cf-networking/${component}.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}${component}:latest", "${REGISTRY_PREFIX}${component}:${CF_NETWORKING_RELEASE_VERSION}"]
  name = component

  matrix = {
    "component" = [ "policy-server", "bosh-dns-adapter", "service-discovery-controller" ]
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/cf-networking-release.git#v${CF_NETWORKING_RELEASE_VERSION}:src"
  }
}

variable "BOSH_DNS_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/bosh-dns-release
  default = "1.39.18"
}

target "bosh-dns" {
  dockerfile = "releases/bosh-dns/${component}.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}${component}:latest", "${REGISTRY_PREFIX}${component}:${BOSH_DNS_RELEASE_VERSION}"]
  name = component

  matrix = {
    "component" = [ "bosh-dns" ]
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/bosh-dns-release.git#v${BOSH_DNS_RELEASE_VERSION}:src"
  }
}

variable "CAPI_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/capi-release
  default = "1.225.0"
}

target "capi" {
  dockerfile = "releases/capi/${component}.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}${component}:latest", "${REGISTRY_PREFIX}${component}:${CAPI_RELEASE_VERSION}"]
  name = component
  
  matrix = {
    "component" = [ "cloud-controller", "cc-uploader", "tps-watcher" ]
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/capi-release.git#${CAPI_RELEASE_VERSION}:src"
  }
}

variable "DIEGO_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/diego-release
  default = "2.128.0"
}

target "diego" {
  dockerfile = "releases/diego/${component}.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}${component}:latest", "${REGISTRY_PREFIX}${component}:${DIEGO_RELEASE_VERSION}"]
  name = component
  
  matrix = {
    "component" = [ "auctioneer", "bbs", "locket", "route-emitter", "ssh-proxy" ]
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/diego-release.git#v${DIEGO_RELEASE_VERSION}:src"
  }
}

variable "LOGGREGATOR_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/loggregator-release
  default = "107.0.24"
}

target "loggregator" {
  dockerfile = "releases/loggregator/${component}.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}${component}:latest", "${REGISTRY_PREFIX}${component}:${LOGGREGATOR_RELEASE_VERSION}"]
  name = component
  
  matrix = {
    "component" = [ "doppler", "reverse-log-proxy", "reverse-log-proxy-gateway", "traffic-controller" ]
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/loggregator-release.git#v${LOGGREGATOR_RELEASE_VERSION}:src"
  }
}

variable "LOGGREGATOR_AGENT_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/loggregator-agent-release
  default = "8.3.13"
}

target "loggregator-agent" {
  dockerfile = "releases/loggregator-agent/${component}.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}${component}:latest", "${REGISTRY_PREFIX}${component}:${LOGGREGATOR_AGENT_RELEASE_VERSION}"]
  name = component
  
  matrix = {
    "component" = [ "syslog-agent", "syslog-binding-cache", "loggregator-agent", "forwarder-agent", "udp-forwarder" ]
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/loggregator-agent-release.git#v${LOGGREGATOR_AGENT_RELEASE_VERSION}:src"
  }
}

variable "LOG_CACHE_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/log-cache-release
  default = "3.2.4"
}

target "log-cache" {
  dockerfile = "releases/log-cache/log-cache.Dockerfile"
  tags = [  "${REGISTRY_PREFIX}${component}:latest" , "${REGISTRY_PREFIX}${component}:${LOG_CACHE_RELEASE_VERSION}"]
  name = component
  
  matrix = {
    "component" = [ "cf-auth-proxy", "gateway", "log-cache", "syslog-server" ]
  }

  args = {
    "component" = component
    "LOG_CACHE_RELEASE_VERSION" = LOG_CACHE_RELEASE_VERSION
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/log-cache-release.git#v${LOG_CACHE_RELEASE_VERSION}:src"
  }
}

variable "CF_DEPLOYMENT_VERSION" {
  # renovate: depName=cloudfoundry/cf-deployment
  default = "54.6.0"
}

target "fileserver" {
  dockerfile = "releases/diego/fileserver.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}fileserver:latest", "${REGISTRY_PREFIX}fileserver:${CF_DEPLOYMENT_VERSION}" ]
  args = {
    "CF_DEPLOYMENT_VERSION" = CF_DEPLOYMENT_VERSION
  }

  contexts = {
    "files" = "releases/diego/files"
  }
}

variable "UAA_RELEASE_VERSION" {
  # renovate: depName=cloudfoundry/uaa-release
  default = "78.7.0"
}

target "uaa" {
  dockerfile = "releases/uaa/uaa.Dockerfile"
  tags = [ "${REGISTRY_PREFIX}uaa:latest", "${REGISTRY_PREFIX}uaa:${UAA_RELEASE_VERSION}" ]
  args = {
    "UAA_RELEASE_VERSION" = UAA_RELEASE_VERSION
  }

  contexts = {
    "src" = "https://github.com/cloudfoundry/uaa-release.git#v${UAA_RELEASE_VERSION}:src/uaa"
    "files" = "releases/uaa/files"
  }
}

variable "CREDHUB_RELEASE_VERSION" {
  # renovate: depName=pivotal/credhub-release
  default = "2.14.18"
}

target "credhub" {
  tags = [ "${REGISTRY_PREFIX}credhub:latest", "${REGISTRY_PREFIX}credhub:${CREDHUB_RELEASE_VERSION}" ]

  context = "https://github.com/pivotal/credhub-release.git#${CREDHUB_RELEASE_VERSION}:src/credhub"
}

variable "CFLINUXFS4_VERSION" {
  # renovate: depName=cloudfoundry/cflinuxfs4-release
  default = "1.304.0"
}

target "cflinuxfs4" {
  dockerfile = "releases/cflinuxfs4/Dockerfile"
  tags = [ "${REGISTRY_PREFIX}cflinuxfs4:${CFLINUXFS4_VERSION}" ]

  args = {
    "CFLINUXFS4_VERSION" = CFLINUXFS4_VERSION
  }
}

target "misc" {
  dockerfile = "releases/capi/${component}.Dockerfile"
  tags = [  "${REGISTRY_PREFIX}${component}:latest" ]
  name = component

  matrix = {
    "component" = [ "blobstore", "cc-nginx" ]
  }

  contexts = {
    "files" = "releases/capi/files"
  }
}
