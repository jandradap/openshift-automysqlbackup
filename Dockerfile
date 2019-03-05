# Build
FROM golang:1.9 as builder

RUN go get -d -v github.com/odise/go-cron
WORKDIR /go/src/github.com/odise/go-cron
RUN CGO_ENABLED=0 GOOS=linux go build -o go-cron bin/go-cron.go

# Package
FROM debian:stretch-slim

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="openshift-automysqlbackup" \
  org.label-schema.description="automysqlbackup non root container" \
  org.label-schema.url="http://andradaprieto.es" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/jandradap/openshift-automysqlbackup" \
  org.label-schema.vendor="Jorge Andrada Prieto" \
  org.label-schema.version=$VERSION \
  org.label-schema.schema-version="1.0" \
  maintainer="Jorge Andrada Prieto <jandradap@gmail.com>" \
  org.label-schema.docker.cmd=""

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    gnupg \
    dirmngr \
    bzip2 \
  && rm -rf /var/lib/apt/lists/*

RUN set -uex; \
  key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
  export GNUPGHOME="$(mktemp -d)"; \
  gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key"; \
  gpg --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
  gpgconf --kill all; \
  rm -rf "$GNUPGHOME"; \
  apt-key list --list-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5

ENV MYSQL_MAJOR 8.0
ENV MYSQL_VERSION 8.0.15-1debian9

RUN echo "deb http://repo.mysql.com/apt/debian/ stretch mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

RUN apt-get update \
  && apt-get install -y mysql-community-client-core="${MYSQL_VERSION}" \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/default /etc/mysql

COPY --from=builder /go/src/github.com/odise/go-cron/go-cron /usr/local/bin
COPY rootfs/start.sh /usr/local/bin
COPY rootfs/automysqlbackup /usr/local/bin
COPY rootfs/my.cnf /etc/mysql

RUN chmod +x /usr/local/bin/go-cron /usr/local/bin/automysqlbackup /usr/local/bin/start.sh

WORKDIR /backup

ENV USERNAME=           \
    PASSWORD=           \
    DBHOST=localhost    \
    DBNAMES=all         \
    DBPORT=3306         \
    BACKUPDIR="/backup" \
    MDBNAMES=           \
    DBEXCLUDE=""        \
    CREATE_DATABASE=yes \
    SEPDIR=yes          \
    DOWEEKLY=6          \
    COMP=gzip           \
    COMMCOMP=no         \
    LATEST=no           \
    MAX_ALLOWED_PACKET= \
    SOCKET=             \
    PREBACKUP=          \
    POSTBACKUP=         \
    ROUTINES=yes        \
    CRON_SCHEDULE=

CMD ["start.sh"]
