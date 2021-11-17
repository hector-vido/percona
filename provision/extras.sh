#!/bin/bash

mkdir -p /root/.ssh
cp /vagrant/files/key /root/.ssh/id_rsa
cp /vagrant/files/key.pub /root/.ssh/id_rsa.pub
cp /vagrant/files/key.pub /root/.ssh/authorized_keys
chmod 400 /root/.ssh/*

# Cria swap se não existir
if [ "$(swapon -v)" == "" ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=512
  chmod 0600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile       swap    swap    defaults        0       0' >> /etc/fstab
fi

apt-get update
apt-get install -y docker.io docker-compose mariadb-client sysbench

mkdir -p /opt/containers
cp /vagrant/files/{docker-compose.yml,proxysql.cnf} /opt/containers

cp /vagrant/files/containers.service /usr/lib/systemd/system/containers.service

systemctl daemon-reload
systemctl start containers
systemctl enable containers

curl -s localhost > /dev/null
while [ "$?" -ne 0 ]; do
    curl -s localhost > /dev/null
done

curl 'http://172.27.11.40/graph/login' -d user=admin -d password=admin --cookie-jar cookie
docker exec -ti percona_pmm_1 \
  pmm-admin remove postgresql pmm-server-postgresql --server-insecure-tls --server-url=https://admin:admin@localhost/
docker exec -ti percona_pmm_1 \
  pmm-admin add proxysql --username=pmm --password=percona --host=172.27.11.40 --service-name=proxysql --server-url=https://admin:admin@localhost/ --server-insecure-tls
