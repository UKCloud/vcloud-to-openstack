#!/bin/sh
#
. ~/vcloudrc.sh

yum -y install ruby rubygems ruby-devel gcc gcc-c++ git
gem install rest-client
gem install xml-simple

cd ~/
if [ -d vcloud-to-openstack ]; then
    cd vcloud-to-openstack
    git pull
    cd ..
else
    git clone $git_url vcloud-to-openstack
fi

chmod u+x vcloud-to-openstack/files/fetch-vm-list.rb
vcloud-to-openstack/files/fetch-vm-list.rb > ~/vmlist.yaml