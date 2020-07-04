ID_OFFSET:=$(shell id -u docker 2</dev/null || echo 0)
UID:=$(shell expr $$(id -u) - ${ID_OFFSET})
GID:=$(shell expr $$(id -g) - ${ID_OFFSET})
USER:=$(shell id -un)
TERMINAL:=$(shell test -t 0 && echo t)
CEPH_RELEASE=octopus
CEPH_ADMIN_RELEASE=octopus
CEPH_USER=${USER}_ceph

all:
	echo "Not supported"

ceph-admin.image:
	docker build --build-arg CEPH_RELEASE=${CEPH_ADMIN_RELEASE} --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

~/.ssh/ceph_id_rsa:
	ssh-keygen -t rsa -f $@

client: ~/.ssh/ceph_id_rsa
	./setup.sh server "${HOST}" ${CEPH_USER}

client.provision: ~/.ssh/ceph_id_rsa
	./setup.sh server.provision "${HOST}" ${CEPH_USER} "${HOSTNAME}"

ceph/.ssh: ~/.ssh/ceph_id_rsa
	mkdir -p $@
	chmod 755 $@
	cp -p ~/.ssh/ceph_id_rsa $@/id_rsa
	cp -p ~/.ssh/ceph_id_rsa.pub $@/id_rsa.pub


ceph-admin.run: ceph-admin.image ceph/.ssh
	docker run --rm -i${TERMINAL} -u ${UID} -v /etc/hosts:/etc/hosts:ro -v$$(pwd)/ceph:/home/${USER} $(basename $@) ceph-deploy --username ${CEPH_USER} -v ${DEPLOY_CMD}

ceph.install:
	${MAKE} ceph-admin.run DEPLOY_CMD='install --release ${CEPH_RELEASE} ${HOST}'
	${MAKE} ceph.host_cmd CMD='apt-get clean'
	${MAKE} ceph.host_cmd CMD='rm -rf /var/lib/apt/lists/*'
	${MAKE} ceph.host_cmd CMD='df -h'

ceph.new:
	${MAKE} ceph-admin.run DEPLOY_CMD='new ${HOSTS}'

ceph.create:
	${MAKE} ceph-admin.run DEPLOY_CMD='mon create-initial'

ceph.gatherkeys:
	${MAKE} ceph-admin.run DEPLOY_CMD='gatherkeys ${HOST}'

ceph.disks:
	${MAKE} ceph-admin.run DEPLOY_CMD='disk list ${HOSTS}'

ceph.disk-create:
	${MAKE} ceph-admin.run DEPLOY_CMD='osd create --data "${DISK}" "${HOST}"'

ceph.admin:
	${MAKE} ceph-admin.run DEPLOY_CMD='admin ${HOST}'

ceph.mgr:
	${MAKE} ceph-admin.run DEPLOY_CMD='mgr create ${HOST}'

ceph.mds:
	${MAKE} ceph-admin.run DEPLOY_CMD='mds create ${HOST}'

ceph.admin_cmd:
	ssh -i ~/.ssh/ceph_id_rsa ${CEPH_USER}@${HOST} sudo ceph ${CMD}

ceph.python-yaml:
	ssh -i ~/.ssh/ceph_id_rsa ${CEPH_USER}@${HOST} sudo apt-get install -y python3-yaml

ceph.host_cmd:
	ssh -t -i ~/.ssh/ceph_id_rsa ${CEPH_USER}@${HOST} sudo ${CMD}
