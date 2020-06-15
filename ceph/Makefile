ID_OFFSET:=$(shell id -u docker 2</dev/null || echo 0)
UID:=$(shell expr $$(id -u) - ${ID_OFFSET})
GID:=$(shell expr $$(id -g) - ${ID_OFFSET})
USER:=$(if ${ceph_user},${ceph_user},$(shell id -un))
TERMINAL:=$(shell test -t 0 && echo t)
CEPH_RELEASE=nautilus

all:
	echo "Not supported"

admin.image:
	docker build --build-arg CEPH_RELEASE=${CEPH_RELEASE} --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

~/.ssh/known_hosts.ceph:
	cp -p ~/.ssh/known_hosts $@

admin.run: admin.image ~/.ssh/known_hosts.ceph
	docker run --rm -i${TERMINAL} -u ${UID} -v ~/.ssh/known_hosts.ceph:/home/${USER}/.ssh/known_hosts -v ~/.ssh/id_rsa:/home/${USER}/.ssh/id_rsa $(basename $@) ceph-deploy ${DEPLOY_CMD}

ceph.install:
	${MAKE} admin.run DEPLOY_CMD='install --release ${CEPH_RELEASE} ${HOSTS}'