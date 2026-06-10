#!/bin/bash

set -e

INSTALLED_BUILPACKS=$(cf curl /v3/buildpacks | jq -r '.resources[] | "#" + .name + "#"')

buildpacks=("nodejs_buildpack" "binary_buildpack")
position=1

if [[ $ALL_BUILDPACKS == "true" ]]; then
  buildpacks+=("dotnet-core_buildpack" "nginx_buildpack" "php_buildpack" "python_buildpack" "r_buildpack" "ruby_buildpack" "staticfile_buildpack")
fi


for buildpack in "${buildpacks[@]}"; do
  if [[ $INSTALLED_BUILPACKS =~ "#$buildpack#" ]]; then
    cf update-buildpack "$buildpack" -p "http://fileserver.127-0-0-1.nip.io/${buildpack}/${buildpack}.zip"
  else
    cf create-buildpack "$buildpack" "http://fileserver.127-0-0-1.nip.io/${buildpack}/${buildpack}.zip" "$position"
  fi
  ((position++))
done
