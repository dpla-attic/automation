
# DPLA Automation

The intention of this project is to provide automated configuration management
for production, development, and staging environments with the same set of
files.

At this early stage, the only hosts being configured are VirtualBox VMs, but the
idea is that, in the future, it should be used for cloud servers, too.


## Installation, VM setup:

### Dependencies

Please install the following tools as documented on their websites:

* [VirtualBox](https://www.virtualbox.org/) (Version 4.3.x is known-good.)
* [Vagrant](http://www.vagrantup.com/) (Version 1.5.x is known-good; 1.6 is
  probably OK but we have not tested it yet.)
* [Ansible](http://www.ansible.com/) (Python package.  Install with `pip install ansible`.  [Installation instructions](http://docs.ansible.com/intro_installation.html))

### Steps
* Copy the following files to their "live" equivalents (removing ".dist") and
  edit them with values specific to your installation:
  * ansible/roles/dbnode/vars/main.yml.dist
  * ansible/group_vars/dbnodes.dist
  * ansible/group_vars/all.dist
    * Note that user shell accounts are configured in `ansible/group_vars/all`,
      and that they require SSH public keys in their ssh_authorized_keys fields.
      The `adminusers` variable is for administrative users who will run
      ansible-playbook.
* Copy or symlink the appropriate Vagrantfile.&lt;name&gt; to Vagrantfile.
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
* Add the following entries to your /etc/hosts file or the equivalent for your
  operating system:
```
192.168.50.4    dbnode1
192.168.50.5    dbnode2
192.168.50.2    dbproxy1
```

## Subsequent Usage

After the hosts are spooled up (as VMs or cloud servers), subsequent commands
with ansible-playbook can be run with one of the administrative user accounts
defined in the file `ansible/group_vars/all`, mentioned above.  If you're using
a VM, the "vagrant" user is necessary for initially provisioning your server,
but once the server is provisioned, and user accounts have been created, you
should use one of those sysadmin accounts for consistency with usage in
production.

For example, say I created an account named "alice" on each server (via
"adminusers" in `ansible/group_vars/all`), I could run this command to execute all
of the user-management plays in the "all.yml" playbook:
```
$ ansible-playbook -u alice -i ansible/<inventory> ansible/all.yml -t users
```
... where `<inventory>` is the inventory file, e.g. "development" or
"production"

## Known issues:

* If you get errors about the vboxfs file system not being available, ssh into
  the virtual machine with `vagrant ssh <host>` and run these commands:
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

