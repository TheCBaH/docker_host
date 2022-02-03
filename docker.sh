#!/bin/sh
set -x
set -eu
if grep -q Alpine /etc/issue; then
  OS=alpine
elif grep -q Ubuntu /etc/issue; then
  OS=ubuntu
else
  echo 'Unknown OS' >&2
  exit 1
fi

do_user() {
  DOCKER_ID=${DOCKER_ID:-9}
  old_user=$(getent passwd 9|cut -d: -f1)
  if [ -n "${old_user}" ]; then
      deluser ${old_user}
  fi
  old_group=$(getent group 9|cut -d: -f1)
  if [ -n "${old_group}" ]; then
      delgroup ${old_group}
  fi
  echo "docker:${DOCKER_ID}:65536" >>/etc/subuid
  echo "docker:${DOCKER_ID}:65536" >>/etc/subgid

  if [ "$OS" = alpine ]; then
    addgroup -S -g ${DOCKER_ID} docker
    adduser -G docker -u ${DOCKER_ID} -D docker
  else
    groupadd --system --gid ${DOCKER_ID} docker
    useradd --system --no-create-home --gid ${DOCKER_ID} --uid ${DOCKER_ID} -r --shell /usr/sbin/nologin  docker
  fi
  if [ -n "${DOCKER_USER:-}" ]; then
    addgroup ${DOCKER_USER} docker
  fi
  if [ -n "${DOCKER_CONFIG_JSON:-}" ]; then
    base64 -d <<_EOF_ | tar -zxv --no-same-owner -C ~
$DOCKER_CONFIG_JSON
_EOF_
    if [ -n "${DOCKER_USER:-}" ]; then
      base64 -d <<_EOF_ | runuser -u ${DOCKER_USER} -- sh -c 'exec tar -zxv --no-same-owner -C ~'
$DOCKER_CONFIG_JSON
_EOF_
    fi
  fi
}

do_docker_data () {
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
}

do_os_ubuntu() {
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
}

do_os_alpine() {
  apk --no-cache add docker
  rc-update add iptables default
  rc-update add docker default
  /etc/init.d/iptables save
  /etc/init.d/iptables start
  /etc/init.d/docker start
  for n in $(seq 20); do
    if grep -q 'completed initialization' /var/log/docker.log; then
      break
    fi
    sleep 1
    tail /var/log/docker.log
  done
}

do_user
do_docker_data
do_os_$OS
docker --version
if [ "${DOCKER_DISABLE_TEST:-}" != 'yes' ]; then
  docker run --rm alpine cat /etc/issue
  docker system prune -af
fi
