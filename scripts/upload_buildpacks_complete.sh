#!/bin/bash

set -e

INSTALLED_BUILPACKS=$(cf curl /v3/buildpacks | jq '.resources[].name')

if [[ $INSTALLED_BUILPACKS == *"dotnet-core_buildpack"* ]]; then
  echo "dotnet-core_buildpack already exists, skipping upload"
else
  cf create-buildpack dotnet-core_buildpack http://file-server.127-0-0-1.nip.io/dotnet-core_buildpack-cflinuxfs4.zip 5
fi

if [[ $INSTALLED_BUILPACKS == *"nginx_buildpack"* ]]; then
  echo "nginx_buildpack already exists, skipping upload"
else
  cf create-buildpack nginx_buildpack http://file-server.127-0-0-1.nip.io/nginx_buildpack-cflinuxfs4.zip 6
fi

if [[ $INSTALLED_BUILPACKS == *"php_buildpack"* ]]; then
  echo "php_buildpack already exists, skipping upload"
else
  cf create-buildpack php_buildpack http://file-server.127-0-0-1.nip.io/php_buildpack-cflinuxfs4.zip 7
fi

if [[ $INSTALLED_BUILPACKS == *"python_buildpack"* ]]; then
  echo "python_buildpack already exists, skipping upload"
else
  cf create-buildpack python_buildpack http://file-server.127-0-0-1.nip.io/python_buildpack-cflinuxfs4.zip 8
fi

if [[ $INSTALLED_BUILPACKS == *"r_buildpack"* ]]; then
  echo "r_buildpack already exists, skipping upload"
else
  cf create-buildpack r_buildpack http://file-server.127-0-0-1.nip.io/r_buildpack-cflinuxfs4.zip 9
fi

if [[ $INSTALLED_BUILPACKS == *"ruby_buildpack"* ]]; then
  echo "ruby_buildpack already exists, skipping upload"
else
  cf create-buildpack ruby_buildpack http://file-server.127-0-0-1.nip.io/ruby_buildpack-cflinuxfs4.zip 10
fi

if [[ $INSTALLED_BUILPACKS == *"staticfile_buildpack"* ]]; then
  echo "staticfile_buildpack already exists, skipping upload"
else
  cf create-buildpack staticfile_buildpack http://file-server.127-0-0-1.nip.io/staticfile_buildpack-cflinuxfs4.zip 11
fi
