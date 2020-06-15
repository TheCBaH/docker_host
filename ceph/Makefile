ID_OFFSET:=$(shell id -u docker 2</dev/null || echo 0)
UID:=$(shell expr $$(id -u) - ${ID_OFFSET})
GID:=$(shell expr $$(id -g) - ${ID_OFFSET})
USER:=$(shell id -un)
TERMINAL:=$(shell test -t 0 && echo t)

all:
	echo "Not supported"

admin.image:
	docker build --build-arg userid=${UID} --build-arg groupid=${GID} --build-arg username=${USER} --build-arg HTTP_PROXY=${http_proxy} -f Dockerfile-$(basename $@) -t $(basename $@) .

admin.run: admin.image
	docker run --rm -i${TERMINAL} -v ~/.ssh:/home/${USER}/.ssh -v ~/.config/gcloud:/home/${USER}/.config/gcloud $(basename $@) ${GCLOUD_CMD}
