# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
yum -y install epel-release
yum -y install ansible ruby rubygems ruby-devel gcc gcc-c++ git
gem install rest-client
gem install xml-simple
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "boxcutter/centos72"

  config.vm.define "ansible" do |server|
	server.vm.hostname = 'ansible'
    server.vm.provision "shell", inline: $script
    server.vm.synced_folder ".", "/home/vagrant/playbooks", type: 'virtualbox'

    server.vm.provider "virtualbox" do |v|
        # v.gui = true
    end
  end


end
