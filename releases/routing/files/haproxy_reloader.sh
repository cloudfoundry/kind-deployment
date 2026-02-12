#!/bin/sh

set -e

kill -HUP $(cat /haproxy/haproxy.pid)
