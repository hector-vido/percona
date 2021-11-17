#!/bin/bash

for I in 20 30; do
	ssh -o stricthostkeychecking=no 172.27.11.$I 'test -f /var/lib/mysql/ibdata1'
	while [ "$?" -ne 0 ]; do
		sleep 5
		ssh 172.27.11.$I 'test -f /var/lib/mysql/ibdata1'
	done
	sleep 10
	ssh 172.27.11.$I 'systemctl stop mysql'
	scp /var/lib/mysql/server-cert.pem /var/lib/mysql/server-key.pem /var/lib/mysql/ca.pem 172.27.11.$I:/var/lib/mysql/
	ssh 172.27.11.$I 'systemctl start mysql && systemctl enable mysql'
	ssh 172.27.11.$I 'pmm-admin config --server-insecure-tls --server-url=https://admin:admin@172.27.11.40'
	ssh 172.27.11.$I 'pmm-admin add mysql --username=pmm --password=percona --query-source=perfschema'
done

curl -s 172.27.11.40 > /dev/null
while [ "$?" -ne 0 ]; do
	curl -s 172.27.11.40 > /dev/null
done

ssh -o stricthostkeychecking=no 172.27.11.10 hostname
for I in 10 20 30; do
	ssh 172.27.11.$I 'pmm-admin config --server-insecure-tls --server-url=https://admin:admin@172.27.11.40'
	ssh 172.27.11.$I 'pmm-admin add mysql --username=pmm --password=percona --query-source=perfschema'
done
