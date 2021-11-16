#!/bin/bash

# Copia a chave SSH
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

apt-get update && apt-get install -y gnupg2 vim

wget --quiet https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
percona-release setup pxc-80
debconf-set-selections <<< 'percona-server-server percona-server-server/root-pass password percona'
debconf-set-selections <<< 'percona-server-server percona-server-server/re-root-pass password percona'
DEBIAN_FRONTEND=noninteractive apt-get install -y percona-xtradb-cluster

systemctl stop mysql
cp /vagrant/files/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
NODE_IP=$(ip address show eth1 | grep -Eo '172\.27\.11\.[0-9]{2}/' | tr -d '/')
SERVER_ID=$(echo $NODE_IP | awk -F . '{print $NF}')
sed -i -e "s/@NODE_IP@/$NODE_IP/" -e "s/@SERVER_ID@/$SERVER_ID/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Bases de Exemplo
if [ "$HOSTNAME" == "db1" ]; then
	systemctl start mysql@bootstrap.service
	echo -e '[mysql]\nuser=root\npassword=percona' > ~/.my.cnf
	apt-get install -y git
	git clone --depth 1 --quiet https://github.com/datacharmer/test_db.git ~/employees-db
	wget --quiet https://downloads.mysql.com/docs/sakila-db.tar.gz -O - | tar -xzv -C ~/
	cd ~/employees-db
	mysql < employees.sql
	cd ~/sakila-db
	cat sakila-schema.sql sakila-data.sql | mysql
	sh /vagrant/provision/bootstrap.sh &
fi
