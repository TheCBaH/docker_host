VOLUME_DIR?=/data
ID_OFFSET:=$(shell id -u docker 2</dev/null || echo 0)
UID:=$(shell expr $$(id -u) - ${ID_OFFSET})
GID:=$(shell expr $$(id -g) - ${ID_OFFSET})
USER:=$(shell id -un)
WORKSPACE=$(shell pwd)
TERMINAL:=$(shell test -t 0 && echo t)

proxy=$(if ${http_proxy},--build-arg http_proxy=${http_proxy})

apt_cache.container:
	-docker kill $(basename $@)
	-docker rm $(basename $@)
	docker build ${proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .
	docker run -d -p 3142:3142 --name $(basename $@) -v $(basename $@):/var/cache/apt-cacher-ng $(basename $@)

apt_cache.volume:
	-docker volume rm $(basename $@)
	docker volume create --driver local --opt type=bind --opt o=bind --opt device=${VOLUME_DIR}/$(basename $@) $(basename $@)

apt_cache.logs:
	docker logs $(basename $@)

apt_cache.run:
	docker run --rm -i${TERMINAL} --volumes-from $(basename $@) $(basename $@) bash

apt_cache.start: apt_cache.container

apt_cache.stop:
	-docker exec $(basename $@) /etc/init.d/apt-cacher-ng stop
	-docker stop $(basename $@)
	-docker rm $(basename $@)

polipo.volume:
	-docker volume rm $(basename $@)
	docker volume create --driver local --opt type=bind --opt o=bind --opt device=${VOLUME_DIR}/$(basename $@) $(basename $@)

polipo.container: polipo.image
	-docker stop $(basename $@)
	-docker rm $(basename $@)
	docker run -d --rm --init -p 8123:8123 --name $(basename $@) -v $(basename $@):/var/cache/$(basename $@) $(basename $@)

polipo.logs:
	docker exec -i${TERMINAL} $(basename $@) cat /var/log/polipo/polipo.log


dnsmasq.logs:
	docker logs $(basename $@)

dnsmasq.start: dnsmasq.image
	docker run --detach --name $(basename $@) --rm -p 53:53/udp -v /etc/hosts:/etc/hosts.host:ro $(basename $@) dnsmasq --no-daemon  --no-resolv --no-hosts --addn-hosts /etc/hosts.host --domain-needed --server 8.8.8.8

dnsmasq.stop:
	-docker stop $(basename $@)

dnsmasq.restart: dnsmasq.stop dnsmasq.start

debootstrap_packages_essential=$(shell cat essential.lst)
debootstrap_packages_core=$(shell cat core-packages.lst)

debootstrap.test:
	echo $($(basename $@)_packages)

debootstrap.container:
	docker build ${proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

debootstrap.init: debootstrap.container
	docker run --userns=host --cap-add=SYS_ADMIN --security-opt apparmor:unconfined  -e http_proxy=${http_proxy} -v $(basename $@):/chroot --rm -i${TERMINAL} $(basename $@) bash -c \
	'debootstrap --variant=minbase --arch=amd64 bionic /chroot http://archive.ubuntu.com/ubuntu/'
	docker run --userns=host -v /proc:/chroot/proc:ro -e http_proxy=${http_proxy} -v $(basename $@):/chroot -i${TERMINAL} --rm $(basename $@) chroot /chroot /bin/bash -c \
	'set -eux; apt-get update; apt-get install -y $($(basename $@)_packages_core);'
	docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@):/chroot -i${TERMINAL} --rm $(basename $@) chroot /chroot /bin/bash -c \
	'apt-get install --no-install-recommends -y $($(basename $@)_packages_essential)'

debootstrap.run:
	docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@):/chroot -i${TERMINAL} --rm $(basename $@) chroot /chroot /bin/bash -i

debootstrap.overlay_run:
	docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@).overlay:/chroot -i${TERMINAL} --rm $(basename $@) chroot /chroot /bin/bash -i

debootstrap.docker:
	cat docker.sh | docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@).overlay:/chroot -i --rm $(basename $@) bash -c \
	'chroot /chroot /bin/bash'

debootstrap.user:
	cat docker.sh | docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@).overlay:/chroot -i --rm $(basename $@)  chroot /chroot /bin/bash -c \
	'set -eux;(echo ubuntu;echo ubuntu)|passwd;echo "/dev/root / ext3 rw,noatime 0 1" >/etc/fstab'

debootstrap_image=image.qcow

debootstrap.image: debootstrap.container
	truncate --size=0 touch $($(basename $@)_image)
	docker run --userns=host -v $(shell pwd)/$($(basename $@)_image):/$($(basename $@)_image) -v $(basename $@).overlay:/chroot --rm -i${TERMINAL} $(basename $@) bash -c \
	'set -eux; env LIBGUESTFS_DEBUG=0 LIBGUESTFS_TRACE=0 virt-make-fs --format=qcow2 --size=2G --type=ext3 /chroot /$($(basename $@)_image)'

debootstrap.qemu:
	docker run --userns=host -v /boot:/boot:ro -v $(shell pwd)/$($(basename $@)_image):/$($(basename $@)_image) --rm -i${TERMINAL} $(basename $@) bash -c \
	'set -eux;qemu-system-x86_64 -curses -append "root=/dev/sda systemd.log_target=kmsg systemd.log_level=debug" -kernel /boot/vmlinuz* -initrd /boot/initrd.* -hda /$($(basename $@)_image) -m 1024 -net user'
	#'set -eux;qemu-system-x86_64 -nographic -append "root=/dev/sda console=ttyS0" -kernel /boot/vmlinuz* -initrd /boot/initrd.* -hda /$($(basename $@)_image) -m 1024 -net user'

debootstrap.volume:
	-docker volume rm $(basename $@)
	docker volume create --driver local --opt type=bind --opt o=bind --opt device=${VOLUME_DIR}/$(basename $@) $(basename $@)
	docker run --rm -i${TERMINAL} --userns=host -v ${basename $@}:/vol alpine sh -ceux 'cd /vol && find . -maxdepth 1 ! -path . -print0| xargs --no-run-if-empty -0 rm -rf'

debootstrap.volume_overlay:
	-docker volume rm $(basename $@).overlay
	docker run --rm -i${TERMINAL} --userns=host -v ${VOLUME_DIR}/$(basename $@).overlay:/vol alpine sh -ceux 'cd /vol && find . -maxdepth 1 ! -path . -print0| xargs --no-run-if-empty -0 rm -rf'
	docker run --rm -i${TERMINAL} --userns=host -v ${VOLUME_DIR}/$(basename $@).workdir:/vol alpine sh -ceux 'cd /vol && find . -maxdepth 1 ! -path . -print0| xargs --no-run-if-empty -0 rm -rf'
	docker volume create --driver local --opt type=overlay \
		--opt o='lowerdir=${VOLUME_DIR}/$(basename $@),upperdir=${VOLUME_DIR}/$(basename $@).overlay,workdir=${VOLUME_DIR}/$(basename $@).workdir' --opt device=overlay $(basename $@).overlay

%.image:
	docker build ${DOCKER_BUILD_OPTS}\
	 --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER}\
	 ${proxy} --build-arg UBUNTU_VER=18.04 -f Dockerfile-$(basename $@) -t $(basename $@) .

%.image_run:
	docker run ${DOCKER_RUN_OPTS} --rm -i${TERMINAL} --user ${UID}:${GID} -v ${CURDIR} -w ${CURDIR} $(basename $@)


gcloud.run: gcloud.image
	docker run --rm -i${TERMINAL} -v ~/.ssh:/home/${USER}/.ssh -v ~/.config/gcloud:/home/${USER}/.config/gcloud $(basename $@) ${GCLOUD_CMD}

%.gcloud:
	docker run --name gcloud-${basename $@} --rm -i${TERMINAL} -v ${WORKSPACE}:/workspace:ro -v ~/.ssh:/home/${USER}/.ssh -v ~/.config/gcloud:/home/${USER}/.config/gcloud gcloud run /workspace/gcloud/$(basename $@)

aws.run: aws.image
	docker run --rm -i${TERMINAL} -v ~/.aws:/home/${USER}/.aws $(basename $@)

tensorflow.image:
	#cd tensorflow;docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} -f devel-cpu.Dockerfile -t $(basename $@) .
	docker build ${proxy} --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} -f tensorflow/Dockerfile-tensorflow-rocm -t $(basename $@) .

tensorflow.run:
	#docker run -i${TERMINAL} --rm -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME} ${basename $@}
	docker run --cap-add=SYS_PTRACE  -i${TERMINAL}  --rm --device=/dev/kfd --device=/dev/dri --group-add sudo --group-add 34 -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME} ${basename $@}

TEHSORFLOW_TAG?=1.13.1
tensorflow.dockerhub:
	docker run -i${TERMINAL} --rm -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -p 8080:8080 -v ${HOME}:${HOME} tensorflow/tensorflow:${TEHSORFLOW_TAG}

#ROCM_TEHSORFLOW_TAG?=rocm2.1-tf1.13-python3
ROCM_TEHSORFLOW_TAG?=rocm2.4-tf1.13-python3
tensorflow.rocm:
	echo chroot --userspec=${UID}:34 / bash
	docker run -i${TERMINAL} --rm --device=/dev/kfd --device=/dev/dri --group-add 34 -e HOME=${HOME} -e USER=${USER} -p 8081:8080 -v ${HOME}:${HOME} --workdir ${HOME} rocm/tensorflow:${ROCM_TEHSORFLOW_TAG}

PYTORCH_TAG?=1.1.0-cuda10.0-cudnn7.5-runtime
pytorch.dockerhub:
	#docker run -i${TERMINAL} --rm -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME} pytorch/pytorch:${PYTORCH_TAG}
	docker run -i${TERMINAL} --rm -v ${HOME}:${HOME} pytorch/pytorch:${PYTORCH_TAG}

pytorch.image:
	docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} ${proxy} -f pytorch/Dockerfile-pytorch-rocm -t $(basename $@) .

pytorch.run:
	 docker run --cap-add=SYS_PTRACE  -i${TERMINAL}  --rm --device=/dev/kfd --device=/dev/dri --group-add sudo --group-add 34 -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME} ${basename $@}

#ROCRCOM_M_PYTORCH_TAG?=rocm2.1_ubuntu16.04_py3.6_pytorch_gfx900
ROCRCOM_M_PYTORCH_TAG?=rocm2.3_ubuntu16.04_py3.6_pytorch
pytorch.rocm:
	echo chroot --userspec=${UID}:34 / bash
	docker run -i${TERMINAL} --rm --device=/dev/kfd --device=/dev/dri --group-add 34 -e HOME=${HOME} -e USER=${USER}  -v ${HOME}:${HOME}  rocm/pytorch:${ROCRCOM_M_PYTORCH_TAG}

pytorch.18_04:
	docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} ${proxy} -f pytorch/Dockerfile-pytorch-18.04 -t $(basename $@):18.04 .

pytorch.18_04.run:
	 docker run --cap-add=SYS_PTRACE  -i${TERMINAL}  --rm --device=/dev/kfd --device=/dev/dri --group-add sudo --group-add 34  -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME}  pytorch:18.04


%.qemu_init:
	${MAKE} -C docker_kvm kvm_image $(basename $@).init

%.run_docker_test:
	docker_kvm/kvm_ssh ssh sudo env $(if $(http_proxy), http_proxy=${http_proxy})\
	 DOCKER_USER=${USER} bash -eux -o pipefail <docker.sh

%.docker_test:
	-${MAKE} -C docker_kvm $(basename $@).ssh.stop
	${MAKE} -C docker_kvm $(basename $@).ssh.start
	${MAKE} $(basename $@).run_docker_test
	${MAKE} -C docker_kvm $(basename $@).ssh.stop

softether.image:
	docker build ${proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

vpn_server.config:
	touch $@

softether.run: vpn_server.config
	docker run -i${TERMINAL} --rm --name $(basename $@) --userns=host -v $(realpath $<):/usr/libexec/softether/vpnserver/vpn_server.config --net host --cap-add NET_ADMIN $(basename $@)
