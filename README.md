# anydbver - Docker/Podman version

Andbver with LXD allows to start containers and install sofware similar to bare-metal production environment.
This branch is intended to use hub.docker.com images as possible without or with minimal modifications.

The replication/clusters setup is configured with sidecar/init containers.

`MYSQL_IMG` could be Oracle MySQL or Percona Server

* Use clone and GTID

```
RUN=1 GTID=1 MYSQL_IMG=percona/percona-server:latest bash -xe create_replication.sh
```

* Use clone and binary log file+position

```
RUN=1 GTID=0 MYSQL_IMG=percona/percona-server:latest bash -xe create_replication.sh
```

* Use GTID and offline filesystem copy (works with 5.6, 5.7, 8.0)

```
RUN=1 GTID=1 SNAPSHOT=1 MYSQL_IMG=percona/percona-server:5.6 bash -xe create_replication.sh
```

Destroy:
```
DESTROY=1 bash -xe create_replication.sh
```
