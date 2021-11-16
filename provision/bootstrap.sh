#!/bin/bash

for I in 20 30; do
	ssh -o stricthostkeychecking=no 172.27.11.$I 'systemctl status mysql && systemctl start mysql && systemctl enable mysql'
	while [ "$?" -eq 4 ]; do
		sleep 10
		ssh 172.27.11.$I 'systemctl status mysql && systemctl start mysql && systemctl enable mysql'
	done
done
