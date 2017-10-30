Go IDE in a Container
=========================

This is a fork of saturnism/go-ide.

Major differences for v1.0 include:
* run container as uid 1000 (aka. user) instead of uid 0 (aka. root) and add sudo
* update the base image to `golang:1.8-stretch`
* addition of .dockerignore to prevent sending unnecessary files to the docker server
* install locale `en_US.UTF-8`
* removed container specific config files `vimrc` and `zshrc` (these will be replaced by configs from mackup)
* add application scmpuff
* add application mackup 
* automatic run of `mackup restore` on container start (see `.container_startup.sh`)

About Mackup Restore
-------------------

I was getting tired of adding custom aliases and mappings to my `.vimrc` and `.zshrc` inside the container, so i decided to setup the container to use `mackup` so all my configs are linked inside the container. That way the container will always have all of my custom aliases and mappings.

In order for `mackup restore` to work, you must mount the location of your backed up configs to the container directory `/home/user/Mackup`. See example run command below. By using mackup, i am assuming that the .vimrc file being linked from the backup location will have pathogen setup commands ie. `execute pathogen#infect()`, otherwise the vim extensions installed in the container may not work.

_note: please consult `saturnism/go-ide/vimrc` file because it has some good mappings which you may want to include in your vimrc file at the backup location_

Running the Container
---------------------
Example run command:
```
docker run \
    -it  \
    --rm \
    --mount type=bind,source=$HOME/Dropbox/Mackup,target=/home/user/Mackup \
    --monut type=volume,source=go-src,target=/home/user/go/src \
    tahurt/go-ide:1.0
``` 
    
Building the Container
----------------------
Nothing special if you already have Docker installed:

    $ git clone https://github.com/tahurt/go-ide
    $ cd go-ide
    $ docker build -t go-ide .

