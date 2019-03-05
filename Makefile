VOLUME_DIR?=/data/docker

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

debootstrap.run:
	docker build --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .
	docker run --userns=host --cap-add=SYS_ADMIN --security-opt apparmor:unconfined -e http_proxy=${http_proxy} -v $(basename $@):/chroot --rm -it $(basename $@) bash -c \
	'debootstrap --variant=minbase --arch=amd64 bionic /chroot http://archive.ubuntu.com/ubuntu/'
	docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@):/chroot -it --rm $(basename $@) chroot /chroot /bin/bash -c \
	'set -eux; apt-get update; apt-get install -y make net-tools wpasupplicant wget; apt-get install -y apt-transport-https ca-certificates  curl  gnupg-agent software-properties-common'

debootstrap.docker:
	cat docker.sh | docker run --userns=host -e http_proxy=${http_proxy} -v $(basename $@).overlay:/chroot -i --rm $(basename $@) bash -c \
	'chroot /chroot /bin/bash'

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

aws.run:
	docker build --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .
	docker run --rm -it -v ~/.aws:/root/.aws:ro $(basename $@)
