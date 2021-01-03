#### Development environment for the 2D Computer Graphics course

First, install [Docker Community Edition](https://www.docker.com/community-edition#download).

Then, create a local working directory in your computer.
Let's say its *absolute* path is given by `absolute-path`.

We use a variety of archives that will be updated whenever needed.
The most important are the `rvgs-1.x.x.zip`, `src-1.x.x.zip`, `fonts-1.x.x.zip`
archives.
Here, `x.x` starts at `0.0` and will be incremented for each new release.
Download all these into your local working directory at `absolute-path`.

Now run the docker container as follows

    docker run -it --rm \
               -e USER=$(id -u -n) \
               -e GROUP=$(id -g -n) \
               -e UID=$(id -u) \
               -e GID=$(id -g) \
               -w /home/$(id -u -n) \
               -v `pwd`:/home/$(id -u -n)/host \
               diegonehab/vg

You should be dropped into Ubuntu 20.04 with everything installed, and a directory `/home/<USER>/host` that mirrors the contents of your local `absolute-path` directory.

The following command will extract all archives and create links without the
version numbers.

    for t in *-*.zip; do
        d=$(echo $t | sed -e 's/-.*//g');
        rm -f $d && unzip $t && ln -s ${t/.zip/} $d;
    done

Have fun.
