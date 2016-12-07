#!/bin/sh
#
. ~/vcloudrc.sh

yum -y install ruby rubygems ruby-devel gcc gcc-c++ git
gem install rest-client
gem install xml-simple

cd ~/
git clone $git_url vcloud-to-openstack

chmod u+x vcloud-to-openstack/files/fetch-vm-list.rb
vcloud-to-openstack/files/fetch-vm-list.rb > ~/vmlist.yaml