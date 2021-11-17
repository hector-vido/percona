# Percona Environment

This repository provision a Percona XtraDB Cluster (PXC) with ProxySQL and Percona Monitoring and Management (PMM).

There are 4 machines:

| Name   | Services      |
|--------|---------------|
| db1    | pxc           |
| db2    | pxc           |
| db3    | pxc           |
| extras | proxysql, pmm |

## Provision

Just start vagrant:

```bash
vagrant up
```

> This will take a while...

## PXC

To access the local MySQL inside the **db's** machines:

```bash
mysql -u root -ppercona
```

## Extras

The ProxySQL and PMM are running inside containers on **extras** machine.
They are controlled by a **compose file** through a service named `containers`.

```bash
systemctl status containers
```

### ProxySQL

ProxySQL is inside a container named `percona_proxysql_1` and is listening on default ports: 6032, 6033.

### PMM

PMM is inside a container named `percona_pmm_1` and is listening on default ports: 80, 443.

The PMM address is https://172.27.11.40.

> The user and password are both **admin**
