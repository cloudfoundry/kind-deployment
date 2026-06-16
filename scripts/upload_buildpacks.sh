#!/bin/bash

set -e

INSTALLED_BUILDPACKS=$(cf curl /v3/buildpacks | jq -r '.resources[] | "#" + .name + "#"')

buildpacks=("java-buildpack" "nodejs-buildpack" "go-buildpack" "binary-buildpack")
position=1

if [[ $ALL_BUILDPACKS == "true" ]]; then
  buildpacks+=("dotnet-core-buildpack" "nginx-buildpack" "php-buildpack" "python-buildpack" "r-buildpack" "ruby-buildpack" "staticfile-buildpack")
fi

for buildpack in "${buildpacks[@]}"; do
  buildpack_name=$(echo "$buildpack" | sed 's/-buildpack/_buildpack/')
  buildpack_version=$(yq e ".buildpacks.${buildpack}.tag" "versions.yaml")
  buildpack_zip="${buildpack}-cflinuxfs4-v${buildpack_version}.zip"
  buildpack_url="http://fileserver.127-0-0-1.nip.io/${buildpack}/${buildpack_zip}"
  fallback_buildpack_url="http://fileserver.127-0-0-1.nip.io/${buildpack}/${buildpack}.zip"

  if ! curl -fsSLI "$buildpack_url" >/dev/null 2>&1; then
    buildpack_url="$fallback_buildpack_url"
  fi

  if [[ $INSTALLED_BUILDPACKS =~ "#$buildpack_name#" ]]; then
    cf update-buildpack "$buildpack_name" -p "$buildpack_url"
  else
    cf create-buildpack "$buildpack_name" "$buildpack_url" "$position"
  fi
  ((position++))
done
