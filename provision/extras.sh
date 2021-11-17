#!/bin/bash

mkdir -p /root/.ssh
cp /vagrant/files/key /root/.ssh/id_rsa
cp /vagrant/files/key.pub /root/.ssh/id_rsa.pub
cp /vagrant/files/key.pub /root/.ssh/authorized_keys
chmod 400 /root/.ssh/*

apt-get update
apt-get install -y docker.io docker-compose mariadb-client

mkdir -p /opt/containers
cp /vagrant/files/{docker-compose.yml,proxysql.cnf,grafana.ini} /opt/containers

cp /vagrant/files/containers.service /usr/lib/systemd/system/containers.service

systemctl daemon-reload
systemctl start containers
systemctl enable containers

curl 'http://172.27.11.40/graph/login' -d user=admin -d password=admin --cookie-jar cookie
