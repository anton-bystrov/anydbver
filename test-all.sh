#!/bin/bash
#export VAGRANT_DEFAULT_PROVIDER=lxc
# export VAGRANT_DEFAULT_PROVIDER=lxd
# export LXD_PROFILE=$USER

# use export PROV=lxd for vagrant-lxd
for psver in "5.6.47-rel87.0.1" "5.7.29-32.1" "8.0.18-9.1"; do
    PS=$psver vagrant up
   vagrant destroy -f || true
done

for pxcver in "5.6.45-28.36.1" "5.7.22-29.26.1" "8.0.18-9.3"; do
    PXC=$pxcver vagrant up
   vagrant destroy -f || true
done

DB_USER=root DB_PASS=secret PS=5.7.29-32.1 vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret PS=5.6.20-rel68.0 vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret PS=8.0.19-10.1 vagrant up
vagrant destroy -f || true

DB_USER=root DB_PASS=secret START=1 PXC=5.6.45-28.36.1 PXB=2.3.9-1 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
# should produce error: DB_USER=root DB_PASS=secret START=1 PXC=5.6.45-28.36.1 PXB=2.4.20-1 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret START=1 PXC=5.6.45-28.36.1 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret START=1 PXC=5.7.28-31.41.2 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret START=1 PXC=8.0.18-9.3     DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true

# start and config files
DB_USER=root DB_PASS=secret START=1 PS=8.0.19-10.1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret START=1 PS=5.7.29-32.1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret START=1 PS=5.6.20-rel68.0 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
DB_USER=root DB_PASS=secret START=1 PS=5.6.23-rel72.1 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true
 
# Test separate xtrabackup installation
PXB=2.3.9-1 vagrant up;vagrant destroy -f || true
PXB=2.4.14-1 vagrant up;vagrant destroy -f || true
PXB=8.0.10-1 vagrant up;vagrant destroy -f || true

# Test mongodb
PSMDB=3.6.16-3.6 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf vagrant up
vagrant destroy -f || true
PSMDB=4.0.17-10 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf vagrant up
vagrant destroy -f || true
PSMDB=4.2.3-4 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf vagrant up
vagrant destroy -f || true

PBM=1.1.1-1 vagrant up
vagrant destroy -f || true

# PMM client
PMM_CLIENT=1.17.3-1 vagrant up
vagrant destroy -f || true
PMM_CLIENT=2.5.0-6 vagrant up
vagrant destroy -f || true

# PMM server running inside podman (easier to setup compare to docker)
PMM_SERVER=1.17.3 vagrant up
vagrant destroy -f || true
PMM_SERVER=2.5.0 vagrant up
vagrant destroy -f || true

# Postresql
PPGSQL=11.5-1 DB_PASS=secret START=1 vagrant up
vagrant destroy -f || true
PPGSQL=11.6-2 DB_PASS=secret START=1 vagrant up
vagrant destroy -f || true
PPGSQL=11.7-2 DB_PASS=secret START=1 vagrant up
vagrant destroy -f || true
PPGSQL=12.2-4 DB_PASS=secret START=1 vagrant up
vagrant destroy -f || true
PPGSQL=12.2-4 DB_PASS=secret START=1 DB_OPTS=postgresql/novacuum.conf vagrant up
vagrant destroy -f || true

# percona toolkit
PT=3.2.0-1 vagrant up
vagrant destroy -f || true

# Multi-node setup
PXC=8.0.18-9.3 vagrant up
for i in `seq 1 3` ; do PT=3.2.0-1 PXC=8.0.18-9.3 PMM_CLIENT=2.5.0-6 vagrant up node$i ; done
PMM_SERVER=2.5.0 vagrant up node4
for i in default node1 node2 node3 ; do vagrant ssh $i -- 'hostname;/sbin/ip addr ls|grep "inet "|grep -v "inet 127";rpm -qa|grep -i percona|xargs' ; done
vagrant destroy -f || true

# Percona XtraDB Cluster (PXC) Kubernetes, using k3s one-file distribution
PKO4PXC='1.4.0' vagrant up
# cluster creation requires a few minutes
vagrant destroy -f || true

# MongoDB in Kubernetes, using k3s one-file distribution
PKO4PSMDB='1.4.0' vagrant up
# cluster creation requires a few minutes
vagrant destroy -f || true

# PXC + pmm
K3S=latest vagrant up default
K3S_TOKEN=$(vagrant ssh default -- sudo cat /var/lib/rancher/k3s/server/node-token) K3S_URL="https://$( vagrant ssh default -- hostname -I | cut -d' ' -f1):6443" vagrant up node1 node2 node3
K3S=latest PKO4PXC='1.4.0' K8S_PMM=1 DB_PASS=secret vagrant provision default
vagrant destroy -f || true

# MySQL replication
DB_USER=root DB_PASS=secret START=1 PS=8.0.19-10.1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret START=1 PS=8.0.19-10.1 \
MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) \
DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1 node2
vagrant destroy -f || true

DB_USER=root DB_PASS=secret START=1 PS=5.7.29-32.1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret START=1 PS=5.7.29-32.1 MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1 node2
vagrant destroy -f || true

DB_USER=root DB_PASS=secret START=1 PS=5.6.23-rel72.1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret START=1 PS=5.6.23-rel72.1 MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1 node2
vagrant destroy -f || true

# PXC
DB_USER=root DB_PASS=secret START=1 PXC=5.6.45-28.36.1 DB_OPTS=mysql/pxc5657.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret PXC=5.6.45-28.36.1 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/pxc5657.cnf vagrant provision node1
DB_USER=root DB_PASS=secret PXC=5.6.45-28.36.1 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/pxc5657.cnf vagrant provision node2
vagrant destroy -f || true

DB_USER=root DB_PASS=secret START=1 PXC=5.7.28-31.41.2 DB_OPTS=mysql/pxc5657.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret PXC=5.7.28-31.41.2 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/pxc5657.cnf vagrant provision node1
DB_USER=root DB_PASS=secret PXC=5.7.28-31.41.2 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/pxc5657.cnf vagrant provision node2
vagrant destroy -f || true

DB_USER=root DB_PASS=secret START=1 PXC=8.0.18-9.3     DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
vagrant ssh default -- sudo tar cz /var/lib/mysql/ca.pem /var/lib/mysql/ca-key.pem /var/lib/mysql/client-cert.pem /var/lib/mysql/client-key.pem /var/lib/mysql/server-cert.pem /var/lib/mysql/server-key.pem > secret/pxc-cluster-ssl.tar.gz
DB_USER=root DB_PASS=secret PXC=8.0.18-9.3 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1
DB_USER=root DB_PASS=secret PXC=8.0.18-9.3 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node2
vagrant destroy -f || true

# MongoDB replicaset
PSMDB=4.0.17-10 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf REPLICA_SET=rs0 vagrant up default
PSMDB=4.0.17-10 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf REPLICA_SET=rs0 MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) vagrant up node1 node2
vagrant destroy -f || true

PSMDB=4.2.3-4 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf REPLICA_SET=rs0 vagrant up default
PSMDB=4.2.3-4 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf REPLICA_SET=rs0 MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) vagrant up node1 node2
vagrant destroy -f || true

# Ubuntu
OS=ubuntu/bionic64 DB_USER=root DB_PASS=secret START=1 PS=5.6.42-84.2-1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true

OS=ubuntu/bionic64 DB_USER=root DB_PASS=secret START=1 PS=5.7.25-28-1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true

OS=ubuntu/bionic64 DB_USER=root DB_PASS=secret START=1 PS=8.0.16-7-1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up
vagrant destroy -f || true

# OS is not needed for vagrant provision run
OS=ubuntu/bionic64 DB_USER=root DB_PASS=secret START=1 PS=5.6.42-84.2-1 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret START=1 PS=5.6.42-84.2-1 MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1 node2

OS=ubuntu/bionic64 DB_USER=root DB_PASS=secret START=1 PS=5.7.25-28-1 DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret START=1 PS=5.7.25-28-1 MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1 node2

OS=ubuntu/bionic64 DB_USER=root DB_PASS=secret START=1 PS=8.0.16-7-1    DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
DB_USER=root DB_PASS=secret START=1 PS=8.0.16-7-1 MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1 node2
vagrant destroy -f || true

OS=ubuntu/bionic64 DB_USER=root DB_PASS=secret START=1 PXC=8.0.18-9-3     DB_OPTS=mysql/async-repl-gtid.cnf vagrant up default node1 node2
vagrant ssh default -- sudo tar cz /var/lib/mysql/ca.pem /var/lib/mysql/ca-key.pem /var/lib/mysql/client-cert.pem /var/lib/mysql/client-key.pem /var/lib/mysql/server-cert.pem /var/lib/mysql/server-key.pem > secret/pxc-cluster-ssl.tar.gz
DB_USER=root DB_PASS=secret PXC=8.0.18-9-3 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node1
DB_USER=root DB_PASS=secret PXC=8.0.18-9-3 REPLICATION_TYPE=galera MASTER=$( vagrant ssh default -- hostname -I | cut -d' ' -f1 ) DB_OPTS=mysql/async-repl-gtid.cnf vagrant provision node2
vagrant destroy -f || true


# lxdock
PSMDB=4.2.3-4 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf REPLICA_SET=rs0 lxdock provision default
PSMDB=4.2.3-4 DB_PASS=secret START=1 DB_OPTS=mongo/enable_wt.conf REPLICA_SET=rs0 MASTER=$( lxdock shell default -c hostname -I | cut -d' ' -f1 ) lxdock provision node1
lxdock destroy -f

K3S=latest lxdock provision default


./gen_lxdock.sh anydbver centos/7
PROXYSQL=2.0.12-1 lxdock up default
lxdock destroy -f || true

./gen_lxdock.sh anydbver centos/8
PROXYSQL=2.0.12-1 lxdock up default
lxdock destroy -f || true

./gen_lxdock.sh anydbver ubuntu/bionic
PROXYSQL=2.0.12 lxdock up default
lxdock destroy -f || true



PROXYSQL=2.0.12-1 vagrant up default
vagrant destroy -f || true

OS=centos/8 PROXYSQL=2.0.12-1 vagrant up default
vagrant destroy -f || true

OS=ubuntu/bionic64 PROXYSQL=2.0.12 vagrant provision default
vagrant destroy -f

# MariaDB
MARIADB=10.4.12-1 lxdock provision default
MARIADB=10.4.12-1 DB_USER=root DB_PASS=secret START=1 DB_OPTS=mariadb/async-repl-gtid.cnf lxdock up default


# lxdock, multi-node k8s cluster
K3S=latest K8S_MINIO=yes lxdock up default
K3S_TOKEN=$(lxdock shell default -c cat /var/lib/rancher/k3s/server/node-token) K3S_URL="https://$(lxdock shell default -c hostname -I | cut -d' ' -f3):6443" lxdock up node1 node2
K3S=latest PKO4PXC='1.4.0' lxdock provision default
lxdock destroy -f

# Vanilla MySQL 8.0
./gen_lxdock.sh anydbver centos/7
MYSQL=8.0.20-1 DB_USER=root DB_PASS=secret START=1 DB_OPTS=mysql/async-repl-gtid.cnf lxdock up default
lxdock destroy -f

./gen_lxdock.sh anydbver centos/8
MYSQL=8.0.20-1 DB_USER=root DB_PASS=secret START=1 DB_OPTS=mysql/async-repl-gtid.cnf lxdock up default
lxdock destroy -f

./gen_lxdock.sh anydbver centos/7
ROCKSDB=1 DB_USER=root DB_PASS=secret START=1 PS=5.7.29-32.1 DB_OPTS=mysql/async-repl-gtid.cnf lxdock up
lxdock destroy -f

./gen_lxdock.sh anydbver centos/7 3
PMM_SERVER=2.5.0 lxdock up node2
PMM_CLIENT=2.5.0-6 PMM_URL="https://admin:admin@$(lxdock shell node2 -c hostname -I |cut -d' ' -f 2):443"  lxdock up default
lxdock destroy -f

./gen_lxdock.sh anydbver centos/7 1
DB_USER=root DB_PASS=secret START=1 PS=8.0.19-10.1    DB_OPTS=mysql/async-repl-gtid.cnf lxdock up default
lxdock destroy -f

for MVER in 5.7.29-32.1 8.0.19-10.1 ; do
    ./gen_lxdock.sh anydbver centos/7 2
    DB_USER=root DB_PASS=secret START=1 PS=$MVER DB_OPTS=mysql/async-repl-gtid.cnf lxdock up default
    SYSBENCH=1.0.20-6 lxdock up node1
    lxdock shell node1 -c /vagrant/tools/sysbench_oltp_ro.sh $( lxdock shell default -c hostname -I | cut -d' ' -f1 ) root secret sbtest 2 10000 4 100
    lxdock destroy -f
done
# 5.7.29-32.1 queries:                             3281712 (32815.00 per sec.)
# 8.0.19-10.1 queries:                             2575440 (25752.72 per sec.)

# PG physical replication
./gen_lxdock.sh anydbver centos/7 2
PPGSQL=12.2-4 DB_PASS=secret START=1 lxdock up default
PPGSQL=12.2-4 DB_PASS=secret START=1 MASTER=$( lxdock shell default -c hostname -I | cut -d' ' -f1 ) lxdock up node1


# install https://github.com/Percona-Lab/mysql_random_data_load/
MYSQL_RANDOM_DATA=0.1.12 lxdock up default
lxdock destroy -f