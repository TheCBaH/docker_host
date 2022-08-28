ID_OFFSET:=$(shell id -u docker 2</dev/null || echo 0)
UID:=$(shell expr $$(id -u) - ${ID_OFFSET})
GID:=$(shell expr $$(id -g) - ${ID_OFFSET})
USER:=$(shell id -un)
TERMINAL:=$(shell test -t 0 && echo t)
CEPH_RELEASE=quincy
CEPH_ADMIN_RELEASE=quincy
CEPH_USER=${USER}_ceph

all:
	echo "Not supported"

ceph-admin.image:
	docker build --build-arg CEPH_RELEASE=${CEPH_ADMIN_RELEASE} $(if ${http_proxy},--build-arg http_proxy=${http_proxy}) --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} -f Dockerfile-$(basename $@) -t $(basename $@) .

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


ceph-admin.shell: ceph-admin.image ceph/.ssh
	docker run --rm -i${TERMINAL} -u ${UID} -v /etc/hosts:/etc/hosts:ro -v$$(pwd)/ceph:/home/${USER} $(basename $@) bash

ceph-admin.run: ceph-admin.image ceph/.ssh
	docker run --rm -i${TERMINAL} -u ${UID} -v /etc/hosts:/etc/hosts:ro -v$$(pwd)/ceph:/home/${USER} $(basename $@) ceph-deploy --username ${CEPH_USER} ${OPTS} -v ${DEPLOY_CMD}

ceph.install:
	${MAKE} ceph-admin.run DEPLOY_CMD='install --release ${CEPH_RELEASE} ${HOST}'
	${MAKE} ceph.host_cmd CMD='apt-get clean'
	${MAKE} ceph.host_cmd CMD='rm -rf /var/lib/apt/lists/*'
	${MAKE} ceph.host_cmd CMD='df -h'

ceph.overwrite_conf:
	${MAKE} ceph-admin.run DEPLOY_CMD='--overwrite-conf new ${HOSTS}'

ceph.new:
	${MAKE} ceph-admin.run DEPLOY_CMD='new ${HOSTS}'

ceph.purge:
	${MAKE} ceph-admin.run DEPLOY_CMD='uninstall ${HOST}'
	${MAKE} ceph-admin.run DEPLOY_CMD='purgedata ${HOST}'

ceph.create:
	${MAKE} ceph-admin.run DEPLOY_CMD='mon create-initial'

ceph.gatherkeys:
	${MAKE} ceph-admin.run DEPLOY_CMD='gatherkeys ${HOST} ${HOSTS}'

ceph.disks:
	${MAKE} ceph-admin.run DEPLOY_CMD='disk list ${HOST}'

ceph.disk-create:
	${MAKE} ceph-admin.run DEPLOY_CMD='osd create --data "${DISK}" ${BLOCKDB} "${HOST}"'

ceph.disk-zap:
	${MAKE} ceph-admin.run DEPLOY_CMD='disk zap "${HOST}" "${DISK}"'

ceph.admin:
	${MAKE} ceph-admin.run DEPLOY_CMD='${OPTS} admin ${HOST}'

ceph.mgr:
	${MAKE} ceph-admin.run DEPLOY_CMD='mgr create ${HOST}'

ceph.mon:
	${MAKE} ceph-admin.run DEPLOY_CMD='mon create ${HOST}'

ceph.mon.add:
	${MAKE} ceph-admin.run DEPLOY_CMD='mon add ${HOST}'

ceph.mon.destroy:
	${MAKE} ceph-admin.run DEPLOY_CMD='mon destroy ${HOST}'

ceph.mds:
	${MAKE} ceph-admin.run DEPLOY_CMD='mds create ${HOST}'

ceph.admin_cmd:
	ssh -i ~/.ssh/ceph_id_rsa ${CEPH_USER}@${HOST} sudo ceph ${CMD}

ceph.python-libs:
	ssh -i ~/.ssh/ceph_id_rsa ${CEPH_USER}@${HOST} sudo apt-get install -y python3-distutils python3-yaml

smartmontools:
	./setup.sh smartmontools "${HOST}" ${CEPH_USER}

ceph.host_cmd:
	ssh -t -i ~/.ssh/ceph_id_rsa ${CEPH_USER}@${HOST} sudo ${CMD}

ceph.map_osd:
	./setup.sh server.map_osd "${HOST}" ${CEPH_USER}  osd

/etc/ceph:
	sudo ln -s ${realpath ceph} $@

/mnt/ceph:
	sudo mkdir -p $@

ceph.mount:/etc/ceph /mnt/ceph
	sudo ceph-fuse /mnt/ceph
