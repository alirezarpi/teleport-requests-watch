FROM alpine:latest

WORKDIR /trc

RUN apk update && \
      apk add --no-cache curl && \
      curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
      chmod +x ./kubectl && \
      mv ./kubectl /usr/local/bin/kubectl

COPY ./trc.sh /trc/trc.sh

ENTRYPOINT /trc/trc.sh
