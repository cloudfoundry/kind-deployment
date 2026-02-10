#!/bin/bash

set -e

service rpcbind start

exec /usr/local/bin/nfsv3driver "$@"
