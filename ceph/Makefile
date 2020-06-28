ID_OFFSET:=$(shell id -u docker 2</dev/null || echo 0)
UID:=$(shell expr $$(id -u) - ${ID_OFFSET})
GID:=$(shell expr $$(id -g) - ${ID_OFFSET})
USER:=$(if ${ceph_user},${ceph_user},$(shell id -un))
TERMINAL:=$(shell test -t 0 && echo t)
CEPH_RELEASE=octopus
CEPH_ADMIN_RELEASE=octopus

all:
	echo "Not supported"

ceph-admin.image:
	docker build --build-arg CEPH_RELEASE=${CEPH_ADMIN_RELEASE} --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

~/.ssh/known_hosts.ceph:
	cp -p ~/.ssh/known_hosts $@

ceph/.ssh:
	mkdir -p $@
	chmod 755 $@
	cp -p ~/.ssh/id_rsa $@/id_rsa
	cp -p ~/.ssh/id_rsa.pub $@/id_rsa.pub

ceph-admin.run: ceph-admin.image ceph/.ssh
	docker run --rm -i${TERMINAL} -u ${UID} -v /etc/hosts:/etc/hosts:ro -v$$(pwd)/ceph:/home/${USER} $(basename $@) ceph-deploy --username ${USER}_ceph -v ${DEPLOY_CMD}

ceph.install:
	${MAKE} ceph-admin.run DEPLOY_CMD='install --release ${CEPH_RELEASE} ${HOSTS}'

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
	ssh ${USER}_ceph@${HOST} sudo ceph ${CMD}
