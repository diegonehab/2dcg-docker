#### Development environment for the 2D Computer Graphics course

First, install [Docker Community Edition](https://www.docker.com/community-edition#download).

Then, create a local working directory in your computer.  Let's say its *absolute* path is given by `absolute-path` Place all the required packages (i.e., rvgs-1.00.zip, src-1.00.zip, fonts-1.00.zip) in the local working
directory.

Now run the docker container as follows

    docker run -e USER=$$(id -u -n) -e GROUP=$$(id -g -n) -e UID=$$(id -u) -e   GID=$$(id -g) -it -w /home/$$(id -u -n) --rm -v `pwd`:/home/$$(id -u -n)/host

You should be dropped into Ubuntu 18.04 with everything installed, and a directory `/home/<USER>/host` that mirrors the contents of your local `absolute-path` directory.

Have fun.
