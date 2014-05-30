
# DPLA Automation

The intention of this project is to provide automated configuration management
for production, development, and staging environments with the same set of
files.

At this early stage, the only hosts being configured are VirtualBox VMs, but the
idea is that, in the future, it should be used for cloud servers, too.


## Installation, VM setup:

TODO: dependencies:  VirtualBox, Vagrant, Ansible

* Copy the following files to their "live" equivalents (removing ".dist") and
  edit them with values specific to your installation:
  * ansible/roles/dbnode/vars/main.yml.dist
  * ansible/group_vars/dbnodes.dist
  * ansible/group_vars/all.dist
    * Note that user shell accounts are configured in ansible/group_vars/all,
      and that they require SSH public keys in their ssh_authorized_keys fields.
* Copy or symlink the appropriate Vagrantfile.<name> to Vagrantfile.
  At the moment, this means symlink Vagrantfile.bigcouch to Vagrantfile.
  In the future, there will be more hosts in our configuration than you'll want
  to have running simultaneously as VMs.
* Bring up the VMs in a shell:
```
$ cd /dir/with/Vagrantfile
$ vagrant up
$ ansible-playbook -i ansible/development -u vagrant \
  --private-key=$HOME/.vagrant.d/insecure_private_key ansible/all.yml
```


## Known issues:

* If you get errors about the vboxfs file system not being available, ssh into
  the virtual machine with "vagrant ssh <host>" and run these commands:
```
$ sudo /etc/init.d/vboxadd setup
$ sudo mount -t vboxsf -o uid=`id -u vagrant`,gid=`getent group vagrant | \
  cut -d: -f3` /vagrant /vagrant
$ sudo mount -t vboxsf -o uid=`id -u vagrant`,gid=`id -g vagrant` \
  /vagrant /vagrant
```
  I'll eventually create an Ansible playbook to handle this situation, which is
  a known issue with Vagrant with regard to Debian's apt-get upgrade of kernel
  packages.


## Tips:

* The first time you create a VM, it has to do an extensive package upgrade
  of the the software in the base image, after which you should restart the VM
  with "vagrant reload," and then watch out for the known issue, above,
  regarding vboxfs.  After that, you shouldn't have to do this again.
* You probably want to exclude `$HOME/VirtualBox VMs/` from any backup jobs that
  you have going on.  The VMs can be recreated at any time, as long as you
  aren't storing data that can't be regenerated.
* If you destroy and re-create a VM, you should delete the old public key
  from `$HOME/.ssh/known_hosts` to avoid getting an error when you run
  ansible-playbook again.  Look for the hostname in addition to its IP address.


##To do:

* Add user accounts w. ssh public keys.
* Add firewall configuration.
