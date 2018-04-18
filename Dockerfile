FROM gcr.io/learned-stone-189802/base-ide:latest 

ENV \
    GOPATH=/home/user/go \
    PATH="/usr/local/go/bin:/home/user/go/bin:${PATH}" \
    GO_VERSION=1.10.1 \
    DEP_VERSION=v0.4.1

#INSTALL go
RUN \
    curl https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | \
    sudo tar zxv --directory /usr/local

#INSTALL dep (dependency management for go: https://github.com/golang/dep)
RUN curl -L -o /usr/local/bin/dep https://github.com/golang/dep/releases/download/${DEP_VERSION}/dep-linux-amd64 && \
    chmod ugo+rx /usr/local/bin/dep

#INSTALL Google Cloud SDK (gcloud), note: requires python2.7.x
#RUN curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GOOGLE_CLOUD_SDK_VERSION}-linux-x86_64.tar.gz | \
#    tar -C /home/user -zxv && \
#    /home/user/google-cloud-sdk/install.sh && \
#    /home/user/google-cloud-sdk/bin/gcloud components install app-engine-go

#Get some useful go packages
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

#SETUP YCM with go-completer
RUN cd /home/user/.vim/bundle/YouCompleteMe && \
    ./install.py --go-completer

COPY --chown=1000:1000 \
    .entrypoint.sh \
    /home/user/

VOLUME ["/home/user/go/src"]

ENTRYPOINT ["/home/user/.entrypoint.sh"]

LABEL \
    NAME="tahurt/go-ide" \
    RUN="docker run -it --rm --mount type=volume,source=go-src,target=/home/user/go/src --mount type=bind,source=\$HOME/Dropbox/Mackup,target=/home/user/Mackup tahurt/go-ide" \
    RUN_WITH_SSH_AGENT="docker run -it --rm --mount type=volume,source=go-src,target=/home/user/go/src --mount type=bind,source=\$HOME/Dropbox/Mackup,target=/home/user/Mackup --mount type=bind,source=\$SSH_AUTH_SOCK,target=/tmp/ssh_auth.sock --env SSH_AUTH_SOCK=/tmp/ssh_auth.sock tahurt/go-ide" \
    MAINTAINER="taylor.a.hurt@gmail.com"
