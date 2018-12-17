.PHONY: build push run share

IMG:=diegonehab/image-base

build:
	docker build -t $(IMG) .

push: build
	docker push $(IMG)

pull:
	docker pull $(IMG)

run:
	docker run -e USER=$$(id -u -n) -e GROUP=$$(id -g -n) -e UID=$$(id -u) -e GID=$$(id -g) -it --rm $(IMG)

share:
	docker run -e USER=$$(id -u -n) -e GROUP=$$(id -g -n) -e UID=$$(id -u) -e GID=$$(id -g) -it --rm -v `pwd`:/host $(IMG)
