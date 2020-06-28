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

ceph-admin.run: ceph-admin.image ~/.ssh/known_hosts.ceph
	docker run --rm -i${TERMINAL} -u ${UID} -v /etc/hosts:/etc/hosts:ro -v$$(pwd)/ceph:/home/${USER} -v ~/.ssh/known_hosts.ceph:/home/${USER}/.ssh/known_hosts -v ~/.ssh/id_rsa:/home/${USER}/.ssh/id_rsa $(basename $@) ceph-deploy --username ceph_${USER} -v ${DEPLOY_CMD}

ceph.install:
	${MAKE} ceph-admin.run DEPLOY_CMD='install --release ${CEPH_RELEASE} ${HOSTS}'

ceph.new:
	${MAKE} ceph-admin.run DEPLOY_CMD='new ${HOSTS}'

ceph.mon:
	${MAKE} ceph-admin.run DEPLOY_CMD='mon create-initial'
