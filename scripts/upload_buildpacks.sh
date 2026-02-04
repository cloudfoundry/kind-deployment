#!/bin/bash

set -e

cf create-buildpack java_buildpack http://file-server.127-0-0-1.nip.io/java-buildpack-cflinuxfs4.zip 2
cf create-buildpack nodejs_buildpack http://file-server.127-0-0-1.nip.io/nodejs_buildpack-cflinuxfs4.zip 5
cf create-buildpack go_buildpack http://file-server.127-0-0-1.nip.io/go_buildpack-cflinuxfs4.zip 6
cf create-buildpack binary_buildpack http://file-server.127-0-0-1.nip.io/binary_buildpack-cflinuxfs4.zip 11
