# openshift-automysqlbackup
[![](https://images.microbadger.com/badges/image/jorgeandrada/openshift-automysqlbackup:latest.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:latest "Get your own image badge on microbadger.com")[![](https://images.microbadger.com/badges/version/jorgeandrada/openshift-automysqlbackup:latest.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:latest "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/commit/jorgeandrada/openshift-automysqlbackup:latest.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:latest "Get your own commit badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/jorgeandrada/openshift-automysqlbackup:alpine.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:alpine "Get your own image badge on microbadger.com")[![](https://images.microbadger.com/badges/version/jorgeandrada/openshift-automysqlbackup:alpine.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:alpine "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/commit/jorgeandrada/openshift-automysqlbackup:alpine.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:alpine "Get your own commit badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/jorgeandrada/openshift-automysqlbackup:develop.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:develop "Get your own image badge on microbadger.com")[![](https://images.microbadger.com/badges/version/jorgeandrada/openshift-automysqlbackup:develop.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:develop "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/commit/jorgeandrada/openshift-automysqlbackup:develop.svg)](https://microbadger.com/images/jorgeandrada/openshift-automysqlbackup:develop "Get your own commit badge on microbadger.com")

<a href='https://ko-fi.com/A417UXC'><img height='36' style='border:0px;height:36px;' src='https://az743702.vo.msecnd.net/cdn/kofi2.png?v=0' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

A lightweight, Alpine linux based image for creating and managing scheduled MySQL backups at non-root container.
Runs a slightly modified [AutoMySQLBackup](https://sourceforge.net/projects/automysqlbackup/) utility.


[Forked from](https://github.com/selim13) and modify for Openshift (non-container root).


## Supported tags and respective `Dockerfile` links

- [`latest` (*Dockerfile*)](https://github.com/selim13/docker-automysqlbackup/blob/master/Dockerfile)
- [`2.6-1-debian` (*Dockerfile*)](https://github.com/selim13/docker-automysqlbackup/blob/2.6-1-debian/Dockerfile)
- [`2.6-1-alpine` (*Dockerfile*)](https://github.com/selim13/docker-automysqlbackup/blob/2.6-1-alpine/Dockerfile) without MySQL 8 support

## Version

This image uses AutoMySQLBackup 2.5 from Debian Linux source repository as a base, branched at `2.6+debian.4-1` tag.
Original source can be cloned from `git://anonscm.debian.org/users/zigo/automysqlbackup.git` or taken at the
appropriate [Debian package](https://packages.debian.org/sid/automysqlbackup) page.

Custom modifications:
- passed logging to stdout/stderr
- removed error logs mailing code
- made default configuration more suitable for docker container

# MySQL 8 support

Currently it is not possible to use this image with the default configuration
of MySQL 8. Alpine linux comes with MariaDB's version of mysqldump which doesn't
support newly introduced caching_sha2_password authentication method.

As a workaround you can either completely switch mysqld to an old authentication
method with `default-authentication-plugin=mysql_native_password` option or
change authentication method for a specific user:

```sql
ALTER USER 'username' IDENTIFIED WITH mysql_native_password BY 'password';
```

# Image usage

Let's create a bridge network and start a MySQL container as an example.
```console
docker network create dbtest
docker run --name some-mysql --network dbtest \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:latest
```

For the basic one-shot backup, you can run a container like this:
```console
docker run --network dbtest \
    -v '/var/lib/automysqlbackup:/backup' \
    -e DBHOST=some-mysql \
    -e DBNAMES=all \
    -e USERNAME=root \
    -e PASSWORD=my-secret-pw \
    -e DBNAMES=all \
    jorgeandrada/openshift-automysqlbackup:alpine
```

Container will create dumps of all datebases from MySQL inside `/var/lib/automysqlbackup` directory and exit.

To run container in a scheduled mode, populate `CRON_SCHEDULE` environment variable with a cron expression.
```console
docker run --network dbtest \
    -v '/var/lib/automysqlbackup:/backup' \
    -e DBHOST=some-mysql \
    -e DBNAMES=all \
    -e USERNAME=root \
    -e PASSWORD=my-secret-pw \
    -e DBNAMES=all \
    -e CRON_SCHEDULE="0 0 * * *" \
    jorgeandrada/openshift-automysqlbackup:alpine
```

Instead of passing environment variables though docker, you can also mount a file with their declarations
as volume. See `defaults` file in this image's git repository for the example.
```console
docker run --network dbtest \
    -v '/var/lib/automysqlbackup:/backup' \
    -v '/etc/default/automysqlbackup:/etc/default/automysqlbackup:ro' \
    jorgeandrada/openshift-automysqlbackup:alpine
```

# Usage with docker-compose

For the example of using this image with docker-compose, see [docker-compose.yml](https://github.com/selim13/docker-automysqlbackup/blob/master/docker-compose.yml) file in the image's repository.

Quick tips:
* You can call `automysqlbackup` binary directly for the manual backup: `docker-compose exec mysqlbackup automysqlbackup`
* Use only YAML dictionary for passing CRON_SCHEDULE environment variable `CRON_SCHEDULE: "0 0 * * *"`
as YAML sequence `- CRON_SCHEDULE="0 * * * *"` will preserve quotes breaking go-cron (Issue #1).


## Environment variables

### CRON_SCHEDULE

If set to cron expression, container will start a cron daemon for scheduled backups.

### USERNAME
Username to access the MySQL server.

### PASSWORD
Password to access the MySQL server.

### DBHOST
Host name (or IP address) of MySQL server.

### DBPORT
Port of MySQL server.

### DBNAMES
List of space separated database names for Daily/Weekly Backup. Set to `all` for all databases.

Default value: `all`

### BACKUPDIR
Backup directory location.
Folders inside this one will be created (daily, weekly, etc.), and the subfolders will be database names.

Default value: `/backup`

### MDBNAMES
List of space separated database names for Monthly Backups.

Will mirror DBNAMES if DBNAMES set to `all`.

### DBEXCLUDE
List of DBNAMES to **exclude** if DBNAMES are set to all (must be in " quotes).

### CREATE_DATABASE
Include CREATE DATABASE in backup?

Default value: `yes`

### SEPDIR
Separate backup directory and file for each DB? (yes or no).

Default value: `yes`

### DOWEEKLY
Which day do you want weekly backups? (1 to 7 where 1 is Monday).

Default value: `6`

### COMP
Choose Compression type. (gzip or bzip2)

Default value: `gzip`

### COMMCOMP
Compress communications between backup server and MySQL server?

Default value: `no`

### LATEST
Additionally keep a copy of the most recent backup in a seperate directory.

Default value: `no`

### MAX_ALLOWED_PACKET
The maximum size of the buffer for client/server communication. e.g. 16MB (maximum is 1GB)

### SOCKET
For connections to localhost. Sometimes the Unix socket file must be specified.

### PREBACKUP
Command to run before backups

### POSTBACKUP
Command run after backups

### ROUTINES
Backup of stored procedures and routines

Default value: `yes`

## License
Similar to the original automysqlbackup script, all sources for this image
are licensed under [GPL-2.0](./LICENSE.txt).
