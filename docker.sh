set -eux
deluser uucp
delgroup uucp || true
DOCKER_ID=10
groupadd --gid ${DOCKER_ID} docker
useradd --no-create-home --gid ${DOCKER_ID} --uid ${DOCKER_ID} -r --shell  /bin/nologin  docker
apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg-agent software-properties-common
apt-get install -y --no-install-recommends iptables multiarch-support
env -u http_proxy curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
env -u http_proxy apt-get update
echo 'docker:10:65536' >>/etc/subuid
echo 'docker:10:65536' >>/etc/subgid
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<_EOF_
{
  "userns-remap": "docker",
  "data-root": "/var/lib/docker"
}
_EOF_
env -u http_proxy apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io
