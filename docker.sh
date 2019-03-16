set -eux
deluser uucp
delgroup uucp || true
DOCKER_ID=10
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
delgroup docker
groupadd --system --gid ${DOCKER_ID} docker
useradd --system --no-create-home --gid ${DOCKER_ID} --uid ${DOCKER_ID} -r --shell  /bin/nologin  docker
