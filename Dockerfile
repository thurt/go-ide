FROM golang:1.8-stretch
LABEL NAME="tahurt/go-ide" \
    RUN="docker run \
        -it \
        --rm \
        --mount type=bind,source=$HOME/Dropbox/Mackup,target=/home/user/Mackup \
        --mount type=volume,source=go-src,target=/home/user/go/src tahurt/go-ide" \
    MAINTAINER="taylor.a.hurt@gmail.com"

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'" https://github.com/pypa/pip/issues/4528
ENV LOCALE=en_US.UTF-8 \
    SHELL=zsh \
    EDITOR=vim \
    PYTHON_PIP_VERSION=9.0.1 \
    SCMPUFF_VERSION=0.2.1

#openssl is at least required for python-pip
RUN apt-get update && \
  apt-get install --no-install-recommends -y \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    git \
    locales \
    openssl \
    python-dev \
    python-pip \
    python-setuptools \
    ruby \
    rubygems \
    sudo \
    tmux \
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
    gem cleanup

#INSTALL scmpuff (number aliases for git)
RUN curl -L https://github.com/mroth/scmpuff/releases/download/v${SCMPUFF_VERSION}/scmpuff_${SCMPUFF_VERSION}_linux_amd64.tar.gz | \
    tar -C /usr/local/bin -zxv scmpuff_${SCMPUFF_VERSION}_linux_amd64/scmpuff --strip=1

#SET LOCALE 
RUN sed -i -e "s/# ${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LOCALE

#SETUP USER
RUN groupadd -g 1000 user && useradd -u 1000 -g 1000 -m user && \
    echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

USER user 

RUN go get github.com/nsf/gocode \
           golang.org/x/tools/cmd/goimports \
           github.com/rogpeppe/godef \
           golang.org/x/tools/cmd/guru \
           golang.org/x/tools/cmd/gorename \
           github.com/golang/lint/golint \
           github.com/kisielk/errcheck \
           github.com/jstemmer/gotags \
           github.com/garyburd/go-explorer/src/getool

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

RUN curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | /bin/zsh || true

COPY --chown=1000:1000 \
    .tmux.conf \
    .mackup.cfg \
    .container_startup.sh \
    /home/user/

COPY --chown=1000:1000 \
    .tmuxinator \
    /home/user/.tmuxinator

VOLUME ["/home/user/go/src"]

ENTRYPOINT ["/home/user/.container_startup.sh"]
