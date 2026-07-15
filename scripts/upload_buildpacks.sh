#!/bin/bash

set -e

. scripts/tools.sh

tools::install::crane

INSTALLED_BUILDPACKS=$(cf curl /v3/buildpacks | jq -r '.resources[] | "#" + .name + "#"')

buildpacks=("java-buildpack" "nodejs-buildpack" "go-buildpack" "binary-buildpack")
stacks=("cflinuxfs4" "cflinuxfs5")
position=1

if [[ $ALL_BUILDPACKS == "true" ]]; then
  buildpacks+=("dotnet-core-buildpack" "nginx-buildpack" "php-buildpack" "python-buildpack" "r-buildpack" "ruby-buildpack" "staticfile-buildpack")
fi

mkdir -p temp/buildpacks

for buildpack in "${buildpacks[@]}"; do
  buildpack_name=$(echo "$buildpack" | sed 's/-buildpack/_buildpack/')
  buildpack_version=$(yq e ".buildpacks.${buildpack}.tag" "versions.yaml")
  buildpack_image=$(yq e ".buildpacks.${buildpack}.image" "versions.yaml")

  crane export "$buildpack_image:$buildpack_version" - | tar -x -C temp/buildpacks -f -

  for stack in "${stacks[@]}"; do
    buildpack_zip="temp/buildpacks/${buildpack}-${stack}-v${buildpack_version}.zip"
    if [[ ! -f "$buildpack_zip" ]]; then
      buildpack_zip="temp/buildpacks/${buildpack}.zip"
    fi

    if [[ $INSTALLED_BUILDPACKS =~ "#$buildpack_name#" ]]; then
      cf update-buildpack "$buildpack_name" -p "$buildpack_zip" -s "$stack"
    else
      cf create-buildpack "$buildpack_name" "$buildpack_zip" "$position"
    fi
    ((position++))
  done
done
