# vCloud Director Migration to OpenStack
There is a migration path to move an existing VM from a vCloud Director VDC to an OpenStack project, however there are a number of steps to go though in order to get the instance booting on OpenStack. These are mostly driver related since the underlying architecture presents different devices to the instance.

VMware provide a utility call OVFTool, a command-line tool used to import and export machine images from vCloud Director. When exporting from vCloud, the VM's disks are saved in a VMDK format. OpenStack is able to import disk images in VMDK format to create a new bootable glance image, from which you can boot your migrated instance on the OpenStack platform.

In order for an instance to boot on the OpenStack platform, the kernel drivers need to support VirtIO devices, and the drivers need to be built into the initrd boot image in order for the rest of the disk and network device to be found. While it is certainly possible to create a cinder volume from the imported glance image, mounting that volume to an existing instance and inserting the VirtIO drivers before booting a new instance from the volume, it is a lot simpler to insert the VirtIO drivers into the initrd boot image before exporting from vCloud.

In addition to ensuring VirtIO drivers are installed, OpenStack makes a number of other recommendations on how to configure images that are to be launched. Details of how to build a new OpenStack image can be found at http://docs.openstack.org/image-guide/create-images-manually.html

All of this is doable for migrating one or two VMs, but it is not scalable. 

## Automating the Driver Installation
So when we have a well defined manual process, it becomes a lot easier to automate the steps. To do this, I have chosen to use Ansible.

* First, to connect to the existing virtual machines running in the vCloud environment and injecting the VirtIO drivers and other OpenStack configurations.

* Second, to call the vCloud API to stop the vApps to be exported. VMware's OVFTool utility will only export a complete vApp, not individual VMs in the vApp, and will only export the machine if it is shutdown. While OVFTool does have a --powerOffSource comandline option, it appears inaffective with vCloud Director.

* To ensure that there is sufficient disk space to hold the exported VMs, we also use Ansible to dynamically provision an instance on OpenStack and attach a cinder volume sufficiently large enough to it, formatting the new disk and mounting it as a temporary workspace.

* Ansible then calls OVFTool for each vApp to be exported, saving the disk images as VMDK files on the new OpenStack instance.

* Once exported, the VMDK disk images are uploaded to create new Glance images, from which a new OpenStack instance can be launched.

## Getting Started
For convenience, the repository provides you with a Vagrant configuration that will create you a local CentOS7 instance running on VirtualBox. If you wish to use this instance you will need to download and install:

 - [Oracle VirtualBox](https://www.virtualbox.org/wiki/Downloads)
 - [Vagrant](https://www.vagrantup.com/downloads.html)

Once these tools are installed, clone this repository to your local workstation and run:
```
vagrant up
vagrant ssh
cd playbooks
```
You will then be in a linux environment all configured and ready to use Ansible and the playbooks in this repository.

Alternatively, you could choose to clone this repository to a VM running on your existing vCloud Director estate, ideally in the same VDC as the VMs you wish to migrate to OpenStack. The rest of these instructions assume that you are using vagrant on your local workstation.

## Initial Configuration
### Setting up vCloud Director and OpenStack Credentials
In order to authenticate with vCloud Director and the OpenStack infrastructure, the scripts in this repository assume that your user credentials are store as environment variables in your local shell session.

For your OpenStack user credentials, you can download the [OpenStack RC File v2](https://cor00005.cni.ukcloud.com/dashboard/project/access_and_security/api_access/openrcv2/) from the "Access & Security" > "API Access" menu in the OpenStack UI.

For your vCloud Director credentials, you can retrieve the relevant values from the [UKCloud Portal](https://portal.skyscapecloud.com/user/api). 

I suggest creating a file called vcloudrc.sh in the top level directory of the repository with the following contents:
```
export VCD_ORG=1-1-11-123456
export VCD_USERID=1234.1.123456
export VCD_PASSWORD='S3creTp@sSw0rd'
export VCD_VDC="My Project VDC (IL2-BASIC)"
export VCD_URL=https://api.vcd.portal.skyscapecloud.com/api
export OS_AUTH_URL=https://cor00005.cni.ukcloud.com:13000/v2.0
export OS_PASSWORD='S3creTp@sSw0rd'
export OS_PROJECT_NAME=MyProject
export OS_USERNAME=user@example.com
```
To include these environment variables in your current session, you can run:
```
source vcloudrc.sh
```
### Ansible Configuration
The playbooks in this repository make use of a dynamic inventory script that leverages the vCloud Directory API in order to generate a HostGroup for every vApp in your specific VDC, and populate host details based on properties held in the VMware metadata. To test connectivity and ensure the script can authenticate with your credentials, you can run the inventory script manually (optionally passing the output through `jq` to pretty-print the JSON):
```
inventory/vcloud-vdc-inventory.rd --list | jq .
```
**NOTE:** The ruby script has a few dependent GEMS which are automatically installed in the vagrant VM. If you are going to run the playbooks on your own VM, you make wish to review the `prepare_control_node.yml` playbook to ensure all the pre-req packages are installed.

If you run the inventory script manually, you will notice that a number of other hostgroups are defined in addition to one for each vApp, notably a group called `vcloud_vms` that contains all the VMs in your VDC, and a hostgroup for each OS distribution, such as `centos_vms` and `windows_vms`. These hostgroups are leveraged in the `inventory/group_vars` directory to set generic settings for each type of VM in our VDC.

### SSH Connection Configuration
You will need to modify the files under `inventory/group_vars` to modify the userid and SSH private keyfile to use when Ansible connects to each VM to be migrated.

If you need to set per-VM setting rather than per-OS type, you can create a `host_vars` directory that contains a `myVMname.yml` file with the override values in.

If you do not have direct access to VMs inside your VDC (for example you are using the vagrant VM on your workstation and do not have vpn connectivity to your VDC) you can make use of SSH's ProxyCommand configuration setting to relay a connection through a bastion / jump server. Edit the `inventory/group_vars/vcloud_vms.yml` file, uncommenting the `ansible_ssh_common_args` line and updating with suitable details for connecting to your jump server.

### Specifying vApps to be Migrated
Create a file called `inventory/migration` that will list the names of the vApps to be migrated. Due to a quirk of how ansible mixes dymanic and static hostgroups, you need to specify each vApp hostgroup as an empty hostgroup (which will be populated later by the dynamic script) before you can use it to define a hostgroup called `migrate_vapps` - this is the hostgroup that all the playbooks make use of to automate the export from vCloud Director.

Your `inventory/migration` file should look something like this:
```
[migrate-vApp1]

[migrate-vApp2]

[migrate-vApp3]

[migrate-vApp4]

[migrate_vapps:children]
migrate-vApp1
migrate-vApp2
migrate-vApp3
migrate-vApp4
```
### Connectivity Test
Before running the playbook, you can check all your setting are correct and ready to go by running:
```
ansible migrate_vapps -m ping
```
All being well, each VM in your vApps should respond with:
```
mig2centos71 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```
***If there are any failures, you need to address the connectivity problem before running the playbook.***

## Ansible Playbook
We have used two separate playbooks, implemented using a number of roles to manage the export of your VMs. The first playbook connects to each VM to be migrated before it is shutdown and ensures it has the VirtIO drivers and other OpenStack recommended configuration settings applied. You can run this playbook with:
```
ansible-playbook migrate-prepare.yml
```
The second playbook is responsible for creating an instance and supporting infrastructure in OpenStack and dynamically mounting sufficient cinder volumes to the instance to hold the exported VMs. You can run this playbook with:
```
ansible-playbook migrate-export.yml
```

License and Authors
-------------------
Authors:
  * Rob Coward (rcoward@ukcloud.com)

Copyright 2016 UKCloud

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
