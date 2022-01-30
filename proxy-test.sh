#!/bin/sh
set -eux
make polipo.start
proxy=$(make --silent polipo.http_proxy)
env http_proxy=$proxy wget -O /dev/null www.docker.com
env http_proxy=$proxy make docker-cli.run CMD='wget -O /dev/null www.docker.com'
make polipo.stop
