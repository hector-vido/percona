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
DEBIAN_FRONTEND=noninteractive apt-get install -y percona-xtradb-cluster pmm2-client

systemctl stop mysql
systemctl enable mysql
cp /vagrant/files/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
NODE_IP=$(ip address show eth1 | grep -Eo '172\.27\.11\.[0-9]{2}/' | tr -d '/')
SERVER_ID=$(echo $NODE_IP | awk -F . '{print $NF}')
sed -i -e "s/@NODE_IP@/$NODE_IP/" -e "s/@SERVER_ID@/$SERVER_ID/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Bases de Exemplo
if [ "$HOSTNAME" == "db1" ]; then
	systemctl start mysql@bootstrap.service
	echo -e '[mysql]\nuser=root\npassword=percona' > ~/.my.cnf
	mysql -e "CREATE USER monitor IDENTIFIED WITH mysql_native_password BY 'proxysql'"
	mysql -e "CREATE USER app IDENTIFIED WITH mysql_native_password BY 'percona'"
	mysql -e "GRANT ALL ON *.* TO app"
	mysql -e "CREATE USER pmm@localhost IDENTIFIED BY 'percona' WITH MAX_USER_CONNECTIONS 10"
	mysql -e "GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ON *.* TO pmm@localhost"
	pmm-admin config --server-insecure-tls --server-url=https://admin:admin@172.27.11.40
	pmm-admin add mysql --username=pmm --password=percona --query-source=perfschema
	apt-get install -y git
	git clone --depth 1 --quiet https://github.com/datacharmer/test_db.git ~/employees-db
	cd ~/employees-db
	mysql -f < employees.sql
	sh -x /vagrant/provision/bootstrap.sh > /tmp/bootstrap-log 2>&1 &
fi
