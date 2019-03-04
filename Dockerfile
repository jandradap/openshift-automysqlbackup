# Build
FROM golang:1.9 as builder

RUN go get -d -v github.com/odise/go-cron
WORKDIR /go/src/github.com/odise/go-cron
RUN CGO_ENABLED=0 GOOS=linux go build -o go-cron bin/go-cron.go

# Package
FROM alpine:3.6

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

RUN apk add --no-cache mysql-client

COPY --from=builder /go/src/github.com/odise/go-cron/go-cron /usr/local/bin
COPY rootfs/start.sh /usr/local/bin
COPY rootfs/automysqlbackup /usr/local/bin

RUN chmod +x /usr/local/bin/go-cron /usr/local/bin/automysqlbackup /usr/local/bin/start.sh

RUN mkdir -p /etc/default /backup \
  && chmod -R a+rwx /backup

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

USER 1001

CMD ["start.sh"]
