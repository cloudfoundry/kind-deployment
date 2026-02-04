#!/bin/bash

set -e

cf create-buildpack binary_buildpack http://file-server.127-0-0-1.nip.io/binary_buildpack-cflinuxfs4.zip 1
cf create-buildpack dotnet-core_buildpack http://file-server.127-0-0-1.nip.io/dotnet-core_buildpack-cflinuxfs4.zip 2
cf create-buildpack go_buildpack http://file-server.127-0-0-1.nip.io/go_buildpack-cflinuxfs4.zip 3
cf create-buildpack java_buildpack http://file-server.127-0-0-1.nip.io/java-buildpack-cflinuxfs4.zip 4
cf create-buildpack nginx_buildpack http://file-server.127-0-0-1.nip.io/nginx_buildpack-cflinuxfs4.zip 5
cf create-buildpack nodejs_buildpack http://file-server.127-0-0-1.nip.io/nodejs_buildpack-cflinuxfs4.zip 6
cf create-buildpack php_buildpack http://file-server.127-0-0-1.nip.io/php_buildpack-cflinuxfs4.zip 7
cf create-buildpack python_buildpack http://file-server.127-0-0-1.nip.io/python_buildpack-cflinuxfs4.zip 8
cf create-buildpack r_buildpack http://file-server.127-0-0-1.nip.io/r_buildpack-cflinuxfs4.zip 9
cf create-buildpack ruby_buildpack http://file-server.127-0-0-1.nip.io/ruby_buildpack-cflinuxfs4.zip 10
cf create-buildpack staticfile_buildpack http://file-server.127-0-0-1.nip.io/staticfile_buildpack-cflinuxfs4.zip 11