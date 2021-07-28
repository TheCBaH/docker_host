#!/bin/bash
set -eu
set -x
env
DOCKER_ID=${DOCKER_ID:-9}
old_user=$(id -un ${DOCKER_ID} 2>/dev/null || true )
if [ -n "${old_user}" ]; then
    deluser ${old_user}
fi
old_group=$(id -Gn ${DOCKER_ID} 2>/dev/null || true )
if [ -n "${old_group}" ]; then
    delgroup ${old_group}
fi
echo "docker:${DOCKER_ID}:65536" >>/etc/subuid
echo "docker:${DOCKER_ID}:65536" >>/etc/subgid
cat /etc/group

groupadd --system --gid ${DOCKER_ID} docker
useradd --system --no-create-home --gid ${DOCKER_ID} --uid ${DOCKER_ID} -r --shell /usr/sbin/nologin  docker
if [ -n "${DOCKER_USER:-}" ]; then
  usermod -aG docker ${DOCKER_USER}
fi
DOCKER_DATA=${DOCKER_DATA:-"/var/lib"}
if [ -d /opt/data ]; then
  DOCKER_DATA=/opt/data/
fi
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<_EOF_
{
  "userns-remap": "docker",
  "data-root": "${DOCKER_DATA}"
}
_EOF_
apt-get update
if [ apt-cache show docker.io >/dev/null 2>&1 ]; then
true
else
  install_software_properties=$(dpkg-query -L software-properties-common >/dev/null 2>&1 || echo y)
  if [ "$install_software_properties" = y ]; then
    apt-get update
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common
  fi
  add-apt-repository universe
  if [ "$install_software_properties" = y ]; then
    env DEBIAN_FRONTEND=noninteractive apt-get purge -y software-properties-common
    apt-get autoremove -y
  fi
  apt-get update
fi
env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker.io
apt-get clean; rm -rf /var/lib/apt/lists/*
docker --version
docker run --rm alpine cat /etc/issue
exit 0
