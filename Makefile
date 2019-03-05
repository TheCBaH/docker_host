AOSP_VOLUME_DIR?=/data/docker

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
	docker run --rm -it $(basename $@)
