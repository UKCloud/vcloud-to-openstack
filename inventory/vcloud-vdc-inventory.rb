#!/usr/bin/env ruby
#

require 'rest-client'
require 'xmlsimple'
require 'json'
require 'getoptlong'

opts = GetoptLong.new(
  [ '--list', '-l', GetoptLong::NO_ARGUMENT ],
  [ '--host', '-h', GetoptLong::REQUIRED_ARGUMENT ]
)

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
  parsed = XmlSimple.xml_in(response.to_str)
rescue => e
  puts e.response
end

inventory = { '_meta' => { 'hostvars' => {} }}
vapp_list = []
vm_vars = {}

parsed['VAppRecord'].each do |vapp|
  begin
    response = RestClient.get vapp['href'], { 'x-vcloud-authorization' => auth_token,
                                              :accept => 'application/*+xml;version=5.6' }
    vapp_details = XmlSimple.xml_in(response.to_str)
  rescue => e
    puts e.response
  end

  vapp_list << vapp_details['name']
  vapp_vms = []
  vapp_details['Children'][0]['Vm'].each do |vm|
    if vm['deployed'] == 'true' && vm['NetworkConnectionSection'][0]['NetworkConnection'][0]['IsConnected'][0] == 'true' then
      vapp_vms << vm['name']
      vm_vars[vm['name']] = { 'ansible_host' => vm['NetworkConnectionSection'][0]['NetworkConnection'][0]['IpAddress'][0] }
    end
  end

  inventory[vapp_details['name']] = { 'hosts' => vapp_vms }
end

inventory['vcloud_vms'] = { 'children' => vapp_list }
inventory['_meta'] = { 'hostvars' => vm_vars }

opts.each do |opt, arg|
  case opt
    when '--list'
      puts inventory.to_json

    when '--host'
      host = arg
      host_vars = vm_vars[host] 
      puts host_vars.to_json
  end
end

