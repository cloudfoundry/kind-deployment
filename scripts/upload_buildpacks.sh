#!/bin/bash

set -e

INSTALLED_BUILPACKS=$(cf curl /v3/buildpacks | jq '.resources[].name')

if [[ $INSTALLED_BUILPACKS == *"java_buildpack"* ]]; then
  echo "java_buildpack already exists, skipping upload"
else
  cf create-buildpack java_buildpack http://file-server.127-0-0-1.nip.io/java-buildpack-cflinuxfs4.zip 1
fi

if [[ $INSTALLED_BUILPACKS == *"nodejs_buildpack"* ]]; then
  echo "nodejs_buildpack already exists, skipping upload"
else
  cf create-buildpack nodejs_buildpack http://file-server.127-0-0-1.nip.io/nodejs_buildpack-cflinuxfs4.zip 2
fi

if [[ $INSTALLED_BUILPACKS == *"go_buildpack"* ]]; then
  echo "go_buildpack already exists, skipping upload"
else
  cf create-buildpack go_buildpack http://file-server.127-0-0-1.nip.io/go_buildpack-cflinuxfs4.zip 3
fi

if [[ $INSTALLED_BUILPACKS == *"binary_buildpack"* ]]; then
  echo "binary_buildpack already exists, skipping upload"
else
  cf create-buildpack binary_buildpack http://file-server.127-0-0-1.nip.io/binary_buildpack-cflinuxfs4.zip 4
fi
