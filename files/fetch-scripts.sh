#!/bin/sh
#
. ~/vcloudrc.sh

yum -y install ruby rubygem ruby-devel gcc gcc-c++ git
gem install rest-client
gem install xml-simple

git clone $git_url

chmod u+x vcloud-to-openstack/files/fetch-vm-list.rb
vcloud-to-openstack/files/fetch-vm-list.rb > ~/vmlist.yaml