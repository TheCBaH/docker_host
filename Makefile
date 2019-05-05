VOLUME_DIR?=/data
ID_OFFSET:=$(shell id -u docker 2</dev/null || echo 0)
UID:=$(shell expr $$(id -u) - ${ID_OFFSET})
GID:=$(shell expr $$(id -g) - ${ID_OFFSET})
USER:=$(shell id -un)
WORKSPACE=$(shell pwd)
TERMINAL:=$(shell test -t 0 && echo t)

apt_cache.container:
	-docker kill $(basename $@)
	-docker rm $(basename $@)
	docker build -f Dockerfile-$(basename $@) -t $(basename $@) .
	docker run -d -p 3142:3142 --name $(basename $@) -v $(basename $@):/var/cache/apt-cacher-ng $(basename $@)

apt_cache.volume:
	-docker volume rm $(basename $@)
	docker volume create --driver local --opt type=bind --opt o=bind --opt device=${VOLUME_DIR}/$(basename $@) $(basename $@)

apt_cache.logs:
	docker logs $(basename $@)

apt_cache.run:
	docker run --rm -it --volumes-from $(basename $@) $(basename $@) bash

apt_cache.stop:
	-docker exec $(basename $@) /etc/init.d/apt-cacher-ng stop
	-docker kill $(basename $@)
	-docker rm $(basename $@)

debootstrap_packages_essential=$(shell cat essential.lst)
debootstrap_packages_core=$(shell cat core-packages.lst)

debootstrap.test:
	echo $($(basename $@)_packages)

debootstrap.container:
	docker build --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

debootstrap.init: debootstrap.container
	docker run --userns=host --cap-add=SYS_ADMIN --security-opt apparmor:unconfined  -e http_proxy=${http_proxy} -v $(basename $@):/chroot --rm -it $(basename $@) bash -c \
	'debootstrap --variant=minbase --arch=amd64 bionic /chroot http://archive.ubuntu.com/ubuntu/'
	docker run --userns=host -v /proc:/chroot/proc:ro -e http_proxy=${http_proxy} -v $(basename $@):/chroot -it --rm $(basename $@) chroot /chroot /bin/bash -c \
	'set -eux; apt-get update; apt-get install -y $($(basename $@)_packages_core);'
	docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@):/chroot -it --rm $(basename $@) chroot /chroot /bin/bash -c \
	'apt-get install --no-install-recommends -y $($(basename $@)_packages_essential)'

debootstrap.run:
	docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@):/chroot -it --rm $(basename $@) chroot /chroot /bin/bash -i

debootstrap.overlay_run:
	docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@).overlay:/chroot -it --rm $(basename $@) chroot /chroot /bin/bash -i

debootstrap.docker:
	cat docker.sh | docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@).overlay:/chroot -i --rm $(basename $@) bash -c \
	'chroot /chroot /bin/bash'

debootstrap.user:
	cat docker.sh | docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@).overlay:/chroot -i --rm $(basename $@)  chroot /chroot /bin/bash -c \
	'set -eux;(echo ubuntu;echo ubuntu)|passwd;echo "/dev/root / ext3 rw,noatime 0 1" >/etc/fstab'

debootstrap_image=image.qcow

debootstrap.image: debootstrap.container
	truncate --size=0 touch $($(basename $@)_image)
	docker run --userns=host -v $(shell pwd)/$($(basename $@)_image):/$($(basename $@)_image) -v $(basename $@).overlay:/chroot --rm -it $(basename $@) bash -c \
	'set -eux; env LIBGUESTFS_DEBUG=0 LIBGUESTFS_TRACE=0 virt-make-fs --format=qcow2 --size=2G --type=ext3 /chroot /$($(basename $@)_image)'

debootstrap.qemu:
	docker run --userns=host -v /boot:/boot:ro -v $(shell pwd)/$($(basename $@)_image):/$($(basename $@)_image) --rm -it $(basename $@) bash -c \
	'set -eux;qemu-system-x86_64 -curses -append "root=/dev/sda systemd.log_target=kmsg systemd.log_level=debug" -kernel /boot/vmlinuz* -initrd /boot/initrd.* -hda /$($(basename $@)_image) -m 1024 -net user'
	#'set -eux;qemu-system-x86_64 -nographic -append "root=/dev/sda console=ttyS0" -kernel /boot/vmlinuz* -initrd /boot/initrd.* -hda /$($(basename $@)_image) -m 1024 -net user'

debootstrap.volume:
	-docker volume rm $(basename $@)
	docker volume create --driver local --opt type=bind --opt o=bind --opt device=${VOLUME_DIR}/$(basename $@) $(basename $@)
	docker run --rm -it --userns=host -v ${basename $@}:/vol alpine sh -ceux 'cd /vol && find . -maxdepth 1 ! -path . -print0| xargs --no-run-if-empty -0 rm -rf'

debootstrap.volume_overlay:
	-docker volume rm $(basename $@).overlay
	docker run --rm -it --userns=host -v ${VOLUME_DIR}/$(basename $@).overlay:/vol alpine sh -ceux 'cd /vol && find . -maxdepth 1 ! -path . -print0| xargs --no-run-if-empty -0 rm -rf'
	docker run --rm -it --userns=host -v ${VOLUME_DIR}/$(basename $@).workdir:/vol alpine sh -ceux 'cd /vol && find . -maxdepth 1 ! -path . -print0| xargs --no-run-if-empty -0 rm -rf'
	docker volume create --driver local --opt type=overlay \
		--opt o='lowerdir=${VOLUME_DIR}/$(basename $@),upperdir=${VOLUME_DIR}/$(basename $@).overlay,workdir=${VOLUME_DIR}/$(basename $@).workdir' --opt device=overlay $(basename $@).overlay

%.image:
	docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

gcloud.run: gcloud.image
	docker run --rm -i${TERMINAL} -v ~/.ssh:/home/${USER}/.ssh -v ~/.config/gcloud:/home/${USER}/.config/gcloud $(basename $@) ${GCLOUD_CMD}

%.gcloud:
	docker run --name gcloud-${basename $@} --rm -it -v ${WORKSPACE}:/workspace:ro -v ~/.ssh:/home/${USER}/.ssh -v ~/.config/gcloud:/home/${USER}/.config/gcloud gcloud run /workspace/gcloud/$(basename $@)

aws.run: aws.image
	docker run --rm -it -v ~/.aws:/home/${USER}/.aws $(basename $@)

tensorflow.image:
	#cd tensorflow;docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f devel-cpu.Dockerfile -t $(basename $@) .
	docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f tensorflow/Dockerfile-tensorflow-rocm -t $(basename $@) .

tensorflow.run:
	#docker run -it --rm -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME} ${basename $@}
	docker run --cap-add=SYS_PTRACE  -it  --rm --device=/dev/kfd --device=/dev/dri --group-add sudo --group-add 34 -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME} ${basename $@}


pytorch.image:
	docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f pytorch/Dockerfile-pytorch-rocm -t $(basename $@) .

pytorch.run:
	 docker run --cap-add=SYS_PTRACE  -it  --rm --device=/dev/kfd --device=/dev/dri --group-add sudo --group-add 34 -u ${UID}:${GID} -e HOME=${HOME} -e USER=${USER} -v ${HOME}:${HOME} ${basename $@}
