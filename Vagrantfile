# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
yum -y install epel-release
yum -y install ansible
cd playbooks
ansible-playbook -v -i inventory/localhost prepare_control_node.yml
SCRIPT

Vagrant.require_version ">= 1.7.0"

Vagrant.configure("2") do |config|
  config.vm.box = "boxcutter/centos72"
  config.ssh.insert_key = false

  config.vm.define "ansible" do |server|
	server.vm.hostname = 'ansible'
    server.vm.provision "shell", inline: $script

    server.vm.synced_folder ".", "/home/vagrant/playbooks", type: 'virtualbox'

    server.vm.provider "virtualbox" do |v|
        # v.gui = true
    end
  end


end
