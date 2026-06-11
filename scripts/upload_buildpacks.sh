#!/bin/bash

set -e

INSTALLED_BUILPACKS=$(cf curl /v3/buildpacks | jq -r '.resources[] | "#" + .name + "#"')

buildpacks=("java-buildpack" "nodejs-buildpack" "go-buildpack" "binary-buildpack")
position=1

if [[ $ALL_BUILDPACKS == "true" ]]; then
  buildpacks+=("dotnet-core-buildpack" "nginx-buildpack" "php-buildpack" "python-buildpack" "r-buildpack" "ruby-buildpack" "staticfile-buildpack")
fi


for buildpack in "${buildpacks[@]}"; do
  if [[ $INSTALLED_BUILPACKS =~ "#$buildpack#" ]]; then
    cf update-buildpack "$buildpack" -p "http://fileserver.127-0-0-1.nip.io/${buildpack}/${buildpack}.zip"
  else
    cf create-buildpack "$buildpack" "http://fileserver.127-0-0-1.nip.io/${buildpack}/${buildpack}.zip" "$position"
  fi
  ((position++))
done
