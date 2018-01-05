#### Development environment for the 2D Computer Graphics course

First, install [Docker Community Edition](https://www.docker.com/community-edition#download).

Then, create a local working directory in your computer.  Let's say its *absolute* path is given by `absolute-path` Place all the required packages (i.e., rvgs-1.00.zip, src-1.00.zip, fonts-1.00.zip) in the local working
directory.

Now run the docker container as follows

	docker run -it -v absolute-path:/home/vg/work diegonehab/vg:latest




You should be dropped into Ubuntu 16.04 with everything installed, and a directory `/home/vg/work` that mirrors the contents of your local `absolute-path` directory.

The user `vg` has password `vg` and has `sudo` priviledges.

Have fun.
