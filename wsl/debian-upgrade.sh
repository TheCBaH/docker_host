#!/bin/sh
set -eu
set -x

upgrade () {
    apt-get update --quiet
    apt-get upgrade -y --quiet
    apt-get dist-upgrade -y --quiet
    apt-get autoremove -y --quiet
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

export DEBIAN_FRONTEND=noninteractive
apt-get update --quiet
apt-get install -y --quiet --no-install-recommends debian-archive-keyring
sed -i -E 's/stretch/buster/' /etc/apt/sources.list
upgrade
sed -i 's/buster/bullseye/g' /etc/apt/sources.list
sed -E -i 's#(bullseye)/updates#\1-security#g' /etc/apt/sources.list
upgrade
