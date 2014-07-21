
# DPLA Automation

The intention of this project is to provide automated configuration management
for production, development, and staging environments with the same set of
files.

At this early stage, the only hosts being configured are VirtualBox VMs, but the
idea is that, in the future, it should be used for cloud servers, too.


## Installation, VM setup:

### Dependencies

Please install the following tools as documented on their websites:

* [VirtualBox](https://www.virtualbox.org/) (Version 4.3)
* [Vagrant](http://www.vagrantup.com/) (Version 1.5 or 1.6)
* [Ansible](http://www.ansible.com/) (Python package.  Install with `pip install ansible`.  [Installation instructions](http://docs.ansible.com/intro_installation.html))

### Steps
* Copy the following files to their "live" equivalents (removing ".dist") and
  edit them with values specific to your installation:
  * ansible/group_vars/all.dist
    * Note that user shell accounts are configured in `ansible/group_vars/all`,
      and that they require SSH public keys in their ssh_authorized_keys fields.
      The `adminusers` variable is for administrative users who will run
      ansible-playbook.
  * ansible/group_vars/development_all.dist
  * ansible/group_vars/frontend_dev.dist
  * ansible/group_vars/frontend_dbs_dev.dist
  * ansible/roles/common/vars/main.yml.dist
  * ansible/roles/dbnode/vars/main.yml.dist
  * ansible/roles/mysql/vars/main.yml.dist
* Copy `Vagrantfile.dist` to `Vagrantfile`.
  In the future, there will be more hosts in our configuration than you'll want
  to have running simultaneously as VMs, and you'll want to edit the default
  Vagrantfile to suit your needs, commenting out VMs that you don't want running.
* Make sure that Vagrant has downloaded the base server image that we'll need
  for our VMs:
```
$ vagrant box add hashicorp/precise64
```
* Add the following entries to your /etc/hosts file or the equivalent for your
  operating system:
```
192.168.50.2    loadbal local.dp.la
192.168.50.4    dbnode1
192.168.50.5    dbnode2
192.168.50.6    webapp1
```
* Bring up the VMs in a shell:
```
$ cd /dir/with/Vagrantfile
$ vagrant up
$ cd ansible
```
An initial run to add your admin shell account to the VMs:
```
$ ansible-playbook -i development -u vagrant \
  --private-key=$HOME/.vagrant.d/insecure_private_key dev_all.yml \
  -t users
```
A second run to configure everything:
```
$ ansible-playbook -i development -u <your username in group_vars/all> \
  dev_all.yml
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
of the user-management plays in the `dev_all.yml` playbook, with the `development`
inventory file:
```
$ cd /path/to/automation/ansible  # contains "ansible.cfg"
$ ansible-playbook -u alice -i development dev_all.yml -t users
```

Please note that `ansible.cfg` needs to be in the working directory of the
`ansible-playbook` command in order for it to read the path to the `roles`
directory, for that to be available to all of the playbooks in `playbooks`.


## Known issues

* **There are bound to be _unknown_ issues, since this project is in a state
  of rapid change.  Note that we have not tagged a release version yet. :-)**
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


## Tips

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

