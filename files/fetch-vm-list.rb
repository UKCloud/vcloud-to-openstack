#!/bin/ruby
#
require 'rest-client'
require 'xmlsimple'
require 'yaml'

begin
  vcloud_session = RestClient::Resource.new("ENV['VCD_URL']/sessions",
                                             "#{ENV['VCD_USERID']}@#{ENV['VCD_ORG']}",
                                              ENV['VCD_PASSWORD'])
  auth = vcloud_session.post '', :accept => 'application/*+xml;version=5.6'
  auth_token = auth.headers[:x_vcloud_authorization]
rescue => e
  puts e.response
end

begin
  response = RestClient.get "ENV['VCD_URL']/query",
                                { :params => { :type => 'vm',
                                               :vdc => ENV['VCD_VDC'] },
                                  'x-vcloud-authorization' => auth_token,
                                  :accept => 'application/*+xml;version=5.6' }
rescue => e
  puts e.response
end

parsed = XmlSimple.xml_in(response.to_str)
# puts parsed.to_json

vmlist = []

parsed['VMRecord'].each do |vm|
  begin
    response = RestClient.get vm['href'], { 'x-vcloud-authorization' => auth_token,
                                            :accept => 'application/*+xml;version=5.6' }
  rescue => e
    puts e.response
  end
  vm_details = XmlSimple.xml_in(response.to_str)
  storage = 0
  vm_details['VirtualHardwareSection'][0]['Item'].each do |item|
    if item['Description'][0] == 'Hard disk' then
      storage += item['HostResource'][0]['vcloud:capacity'].to_i
    end
  end

  vmlist << { vm['name'] => { 'vmname' => vm['name'],
                              'vapp' => vm['containerName'],
                              'status' => vm['status'],
                              'href' => vm['href'],
                              'storage' => storage } }
end

variables = { 'instances' => vmlist }
puts variables.to_yaml
