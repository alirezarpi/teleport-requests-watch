FROM alpine:latest

WORKDIR /trw

RUN apk update && \
      apk add --no-cache curl bash && \
      curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
      chmod +x ./kubectl && \
      mv ./kubectl /usr/local/bin/kubectl

COPY ./trw.sh /trw/trw.sh

ENTRYPOINT bash /trw/trw.sh
