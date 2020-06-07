#!/bin/bash
set -eux
DOCKER_ID=9
old_user=$(id -un ${DOCKER_ID} || true 2>/dev/null)
if [ -n "${old_user}" ]; then
    deluser ${old_user}
fi
old_group=$(id -Gn ${DOCKER_ID} || true 2>/dev/null)
if [ -n "${old_group}" ]; then
    delgroup ${old_group}
fi
echo "docker:${DOCKER_ID}:65536" >>/etc/subuid
echo "docker:${DOCKER_ID}:65536" >>/etc/subgid
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<_EOF_
{
  "userns-remap": "docker",
  "data-root": "/var/lib/docker"
}
_EOF_
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository universe
apt-get install -y --no-install-recommends docker.io
apt-get purge -y software-properties-common
apt-get autoremove -y
delgroup docker
groupadd --system --gid ${DOCKER_ID} docker
useradd --system --no-create-home --gid ${DOCKER_ID} --uid ${DOCKER_ID} -r --shell  /bin/nologin  docker
usermod -aG docker ${SUDO_USER}
systemctl restart docker
