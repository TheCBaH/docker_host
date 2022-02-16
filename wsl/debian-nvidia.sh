#!/bin/bash
set -eu
set -x
export DEBIAN_FRONTEND=noninteractive

apt-get --quiet update
apt-get install -y --quiet --no-install-recommends\
 git\
 less\
 make\
 openssh-client\
 procps\
 psutils\
 rsync\
 vim-tiny\

apt-get install -y --quiet --no-install-recommends iptables

update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

update-alternatives --set editor /usr/bin/vim.tiny

touch /etc/fstab

apt-get install -y --quiet --no-install-recommends docker.io
if [ -n "${SUDO_USER:-}" ]; then
    addgroup ${SUDO_USER} docker
fi
if [ -z "${DOCKER:-}" ]; then
    service docker start
fi

if [ -n "${WITHOUT_CUDA:-}" ]; then
    exit 0
fi

apt-get install -y --quiet --no-install-recommends\
 ca-certificates\
 curl\
 gpg-agent\
 gpg\

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/nvidia.gpg --import
chmod a+r  /etc/apt/trusted.gpg.d/nvidia.gpg
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get auto-remove -y --quiet gpg-agent

apt-get --quiet update
apt-get install -y --quiet --no-install-recommends nvidia-docker2

apt-get clean
rm -rf /var/lib/apt/lists/*

if [ -z "${DOCKER:-}" ]; then
    service docker start
    sleep 1
    docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
fi
