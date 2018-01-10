FROM golang:1.8-stretch
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'" https://github.com/pypa/pip/issues/4528
ENV LOCALE=en_US.UTF-8 \
    SHELL=zsh \
    EDITOR=vim \
    GOPATH=/home/user/go \
    PATH="/home/user/go/bin:${PATH}" \
    DOCKER_VERSION=17.09.0-ce \
    PROTOC_VERSION=3.4.0 \
    DEP_VERSION=v0.3.2 \
    PYTHON_PIP_VERSION=9.0.1 \
    SCMPUFF_VERSION=0.2.1 \
    HUB_VERSION=2.2.9 \
    GOOGLE_CLOUD_SDK_VERSION=183.0.0 \
    DEVD_VERSION=0.8

#openssl is at least required for python-pip
RUN apt-get update && \
  apt-get install --no-install-recommends -y \
    build-essential \
    cmake \
    locales \
    openssl \
    python-dev \
    python-pip \
    python-setuptools \
    ruby \
    ruby-dev \
    rubygems \
    sudo \
    tmux \
    unzip \
    vim-nox \
    zsh \
    && \
  apt-get clean && \
  rm /var/lib/apt/lists/*_*

#distro packages dont have recent versions of pip
RUN pip install \
    pip==${PYTHON_PIP_VERSION} \
    mackup && \
    rm -rf ~/.cache/pip/*

RUN gem install tmuxinator && \
    gem install travis && \
    gem cleanup

#INSTALL protoc (protocol buffer compiler)
RUN curl -L -o /usr/local/protoc.zip https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip /usr/local/protoc.zip -x readme.txt -d /usr/local && \
    rm /usr/local/protoc.zip && \
    chmod o+rx /usr/local/bin/protoc && \
    chmod -R o+rX /usr/local/include/google/ 

#INSTALL dep (dependency management for go: https://github.com/golang/dep)
RUN curl -L -o /usr/local/bin/dep https://github.com/golang/dep/releases/download/${DEP_VERSION}/dep-linux-amd64 && \
    chmod ugo+rx /usr/local/bin/dep

#INSTALL scmpuff (number aliases for git)
RUN curl -L https://github.com/mroth/scmpuff/releases/download/v${SCMPUFF_VERSION}/scmpuff_${SCMPUFF_VERSION}_linux_amd64.tar.gz | \
    tar -C /usr/local/bin -zxv scmpuff_${SCMPUFF_VERSION}_linux_amd64/scmpuff --strip=1

#INSTALL Docker client (excluding the daemon b/c i expect this container will i/a with host's daemon via docker.sock)
RUN curl -L https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | \
    tar -C /usr/local/bin -zxv docker/docker --strip=1

#INSTALL Hub (command-line wrapper for git that makes you better at GitHub)
RUN curl -L https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz | \
    tar -C /usr/local -zxv --exclude=README.md --exclude=LICENSE --exclude=install --strip=1

#INSTALL devd (a local webserver for developers)
RUN curl -L https://github.com/cortesi/devd/releases/download/v${DEVD_VERSION}/devd-${DEVD_VERSION}-linux64.tgz | \
    tar -C /usr/local/bin -zxv --strip=1

#SET LOCALE 
RUN sed -i -e "s/# ${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LOCALE

#SETUP USER
RUN groupadd -g 1000 user && useradd -u 1000 -g 1000 -m user && \
    echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

RUN groupadd -g 126 docker && \
    usermod -a -G docker user

USER user 

#ADD github to ssh known_hosts
# also see this link for explanation of ip ranges i added in ssh-keyscan https://unix.stackexchange.com/a/164434/255117
RUN echo 'FOR CROSS-VERIFICATION, PLEASE CHECK THAT THE SHA256 RSA HASH ON STDOUT MATCHES WITH https://help.github.com/articles/github-s-ssh-key-fingerprints/' && \
    mkdir /home/user/.ssh && \
    ssh-keyscan -t rsa github.com,192.30.252.*,192.30.253.*,192.30.254.*,192.30.255.* | tee -a /home/user/.ssh/known_hosts | ssh-keygen -lf -

#INSTALL Google Cloud SDK (gcloud), note: requires python2.7.x
RUN curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GOOGLE_CLOUD_SDK_VERSION}-linux-x86_64.tar.gz | \
    tar -C /home/user -zxv && \
    /home/user/google-cloud-sdk/install.sh && \
    /home/user/google-cloud-sdk/bin/gcloud components install app-engine-go

RUN go get \
    github.com/garyburd/go-explorer/src/getool \
    github.com/golang/lint/golint \
    github.com/golang/mock/mockgen \ 
    github.com/golang/protobuf/protoc-gen-go \
    github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
    github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger \
    github.com/jstemmer/gotags \
    github.com/kisielk/errcheck \
    github.com/nsf/gocode \
    github.com/mwitkow/go-proto-validators/protoc-gen-govalidators \
    github.com/rogpeppe/godef \
    golang.org/x/tools/cmd/goimports \
    golang.org/x/tools/cmd/gorename \
    golang.org/x/tools/cmd/guru \
    google.golang.org/grpc

RUN mkdir -p ~/.vim/autoload ~/.vim/bundle && \
    git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim && \
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim && \
    git clone git://github.com/tpope/vim-sensible.git ~/.vim/bundle/vim-sensible && \
    git clone https://github.com/Valloric/YouCompleteMe ~/.vim/bundle/YouCompleteMe && \
    git clone https://github.com/garyburd/go-explorer.git ~/.vim/bundle/go-explorer && \
    git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree && \
    git clone https://github.com/fatih/vim-go.git ~/.vim/bundle/vim-go

RUN cd ~/.vim/bundle/YouCompleteMe && \
    git submodule update --init --recursive && \
    ./install.py --gocode-completer

RUN curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | \
    /bin/zsh || true

COPY \
    .tmux.conf \
    .mackup.cfg \
    .container_startup.sh \
    /home/user/
RUN sudo chown 1000:1000 \
    /home/user/.tmux.conf \
    /home/user/.mackup.cfg \
    /home/user/.container_startup.sh 

COPY \
    .tmuxinator \
    /home/user/.tmuxinator/
RUN sudo chown -hR 1000:1000 \
    /home/user/.tmuxinator/

COPY \
    .config \
    /home/user/.config/
RUN sudo chown -hR 1000:1000 \
    /home/user/.config/

VOLUME ["/home/user/go/src"]

ENTRYPOINT ["/home/user/.container_startup.sh"]

LABEL \
    NAME="tahurt/go-ide" \
    RUN="docker run -it --rm --mount type=volume,source=go-src,target=/home/user/go/src --mount type=bind,source=\$HOME/Dropbox/Mackup,target=/home/user/Mackup tahurt/go-ide" \
    RUN_WITH_SSH_AGENT="docker run -it --rm --mount type=volume,source=go-src,target=/home/user/go/src --mount type=bind,source=\$HOME/Dropbox/Mackup,target=/home/user/Mackup --mount type=bind,source=\$SSH_AUTH_SOCK,target=/tmp/ssh_auth.sock --env SSH_AUTH_SOCK=/tmp/ssh_auth.sock tahurt/go-ide" \
    MAINTAINER="taylor.a.hurt@gmail.com"


