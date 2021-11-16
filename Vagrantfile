# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# forks: mysql, mariadb ou percona
# memory, cpus, fork and sample are optional, defaults do:
#   1024,    2, mysql     and 0 respectively

vms = {
  'db1' => {'ip' => '10', 'script' => 'xtradb.sh'},
  'db2' => {'ip' => '20', 'script' => 'xtradb.sh'},
  'db3' => {'ip' => '30', 'script' => 'xtradb.sh'},
  'proxysql' => {'memory' => 256, 'cpus' => 1, 'ip' => '40', 'script' => 'proxysql.sh'},
}

resources = {
  'cpus' => 2,
  'memory' => 2048
}

Vagrant.configure('2') do |config|

  config.vm.box_check_update = false

  vms.each do |name, conf|
    config.vm.define "#{name}" do |my|
      args = [conf['fork'] || 'mysql', conf['sample'] || 0]
      my.vm.box = 'debian/buster64'
      my.vm.hostname = "#{name}.percona.local"
      my.vm.network 'private_network', ip: "172.27.11.#{conf['ip']}"
      my.vm.provision 'shell', path: "provision/#{conf['script']}"
      my.vm.provider 'virtualbox' do |vb|
        vb.memory = conf['memory'] || resources['memory']
        vb.cpus = conf['cpus'] || resources['cpus']
      end
      my.vm.provider 'libvirt' do |lv|
        lv.memory = conf['memory'] || resources['memory']
        lv.cpus = conf['cpus'] || resources['cpus']
        lv.cputopology :sockets => 1, :cores => conf['cpus'] || resources['cpus'], :threads => '1'
      end
    end
  end

end
