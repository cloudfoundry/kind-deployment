#!/bin/bash

set -euo pipefail

cf disable-feature-flag resource_matching
cf enable-feature-flag diego_cnb
cf enable-feature-flag diego_docker
cf enable-feature-flag service_instance_sharing
