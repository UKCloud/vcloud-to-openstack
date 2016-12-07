# vCloud Director Migration to OpenStack
Helper VM and scripts to migrate VMs from vCloud Director to OpenStack.

## HEAT Template
The heat template in this repository has been written to make use of a customised
CentOS7 image that has VMware's ovftool pre-installed.

To deploy the Migration Tools:
```
openstack stack create -t vcloud-migration.yaml -e environment_example.yml --wait migration
```

The template will clone this repository and make use of the vCloud credentials you 
specify in the environment_example.yml file to call the vCloud API and extract
a list of VMs from your VDC. The resulting list will be written as YAML to 
/root/vmlist.yaml and will be used as a variable file for ansible.

## Ansible Playbook
We have used an ansible playbook to automate the migration process, using the
generated list of VMs as a data source. 

If you want to selectively migrate your VMs from vCloud, you should edit the
vmlist.yaml file to only contain the VMs to be migrated.

After editting the vmlist.yaml file, start the process by running:
```
ansible-playbook vm-migrate.yml
```

License and Authors
-------------------
Authors:
  * Rob Coward (rcoward@skyscapecloud.com)

Copyright 2016 Skyscape Cloud Services

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
