#!/usr/bin/env ruby
#
require 'rest-client'
require 'xmlsimple'
require 'json'

begin
  vcloud_session = RestClient::Resource.new("#{ENV['VCD_URL']}/sessions",
                                             "#{ENV['VCD_USERID']}@#{ENV['VCD_ORG']}",
                                              ENV['VCD_PASSWORD'])
  auth = vcloud_session.post '', :accept => 'application/*+xml;version=5.6'
  auth_token = auth.headers[:x_vcloud_authorization]
rescue => e
  puts e.response
end

begin
  response = RestClient.get "#{ENV['VCD_URL']}/query",
                                { :params => { :type => 'vApp',
                                               :vdc => ENV['VCD_VDC'] },
                                  'x-vcloud-authorization' => auth_token,
                                  :accept => 'application/*+xml;version=5.6' }
rescue => e
  puts e.response
end

parsed = XmlSimple.xml_in(response.to_str)
# puts parsed.to_json

vapp_list = {}
vm_list = []

parsed['VAppRecord'].each do |vapp|
    begin
        response = RestClient.get vapp['href'], { 'x-vcloud-authorization' => auth_token,
                                            :accept => 'application/*+xml;version=5.6' }
    rescue => e
        puts e.response
    end
    vapp_details = XmlSimple.xml_in(response.to_str)
#    puts vapp_details['Children'][0]['Vm'].to_json

    vapp_vms = []
    vapp_details['Children'][0]['Vm'].each do |vm|

	#puts vm.to_json
	begin
            if vm['deployed'] == "true" and vm['NetworkConnectionSection'][0]['NetworkConnection'][0]['IsConnected'][0] == "true" then
		ansible_inventory = "%s ansible_host='%s'" % [ vm['name'], vm['NetworkConnectionSection'][0]['NetworkConnection'][0]['IpAddress'][0] ]
	        vapp_vms << ansible_inventory
                vm_list << ansible_inventory
            end
        rescue => e
            puts vm.to_json
	    puts e
        end
    end

    vapp_list[vapp_details['name']] = vapp_vms 
end

vapp_list['vcloud_vms'] = vm_list

puts vapp_list.to_json
#  storage = 0
#  vm_details['VirtualHardwareSection'][0]['Item'].each do |item|
#    if item['Description'][0] == 'Hard disk' then
#      storage += item['HostResource'][0]['vcloud:capacity'].to_i
#    end
#  end
#  if storage > max_workspace then
#    max_workspace = storage
#  end

#  vmlist << { 'vmname' => vm['name'],
#                              'vapp' => vm['containerName'],
#                              'status' => vm['status'],
#                              'href' => vm['href'],
#                              'storage' => storage } 
#end

#variables = { 'instances' => vmlist,
#              'max_workspace' => max_workspace / 1024 }
#puts variables.to_yaml
