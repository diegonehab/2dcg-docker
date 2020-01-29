.PHONY: build push run share

IMG:=diegonehab/vg

build:
	docker build -t $(IMG) .

push: build
	docker push $(IMG)

pull:
	docker pull $(IMG)

run:
	docker run \
		 -e USER=$$(id -u -n) \
	     -e GROUP=$$(id -g -n) \
		 -e UID=$$(id -u) \
		 -e GID=$$(id -g) \
		 -v `pwd`:/home/$$(id -u -n)/host \
		 -it \
		 -w /home/$$(id -u -n) \
		 --rm $(IMG)
