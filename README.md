
# DPLA Automation

[![Build Status](https://travis-ci.org/dpla/automation.svg?branch=master)](https://travis-ci.org/dpla/automation)

The intention of this project is to provide automated configuration management
for production, development, and staging environments with the same set of
files.

You may follow our
[`latest` repository branch](https://github.com/dpla/automation/tree/latest) for
the latest stable release.

**This project no longer represents the majority of our applications.**

## Installation, VM setup:

### Upgrading

If you've already been working with an earlier version of `automation`, please
see README-upgrade-6.0.md.

### Prerequisites and Dependencies

At least when running all of the web application and database services together,
which is the case with the default Vagrantfile mentioned below, we assume a host
machine with at least 8 GB of memory.

Please install the following tools as documented on their websites:

* [VirtualBox](https://www.virtualbox.org/) (Version 5.2.x)
* [Vagrant](http://www.vagrantup.com/) (Version 2.0.x)
* [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest/) (`vagrant plugin install vagrant-vbguest`)
* [Ansible](http://www.ansible.com/) (Version 1.9) (Version 2.x will definitely not work) [installation instructions](http://docs.ansible.com/intro_installation.html)
* Additional dependencies described in the `pip` requirements file (see below)

### Steps

* Clone this project with Git or download the latest
  [zipfile](https://github.com/dpla/automation/archive/master.zip) and open it.  If
  you download the zipfile you won't be able to update it as easily when we issue
  updates.
* Install the additional dependencies using `pip`:
  * `pip install -r requirements.txt`
* Copy the following files to their "live" equivalents (removing ".dist") and
  edit them with values specific to your installation.
  * `ansible/group_vars/all.dist`
    * Note that user shell accounts are configured in `ansible/group_vars/all`,
      and that they require SSH public keys in their ssh_authorized_keys fields.
      The `adminusers` variable is for administrative users who will run
      ansible-playbook.
  * `ansible/group_vars/development.dist`
    * If you're going to be developing DPLA applications, you might want to
      override the `*_use_local_source` variables in some of the roles'
      `defaults` directories, as well as the variables related to the source
      directories.
* Copy `Vagrantfile.dist` to `Vagrantfile`. If you want to perform development work on any of the DPLA applications that will be installed, see the comments in `Vagrantfile` about mounting their working copy directories for "local" deployments.
* Make sure that Vagrant has downloaded the base server image that we'll need
  for our VMs:
```
$ vagrant box add ubuntu/trusty64
```
* Add the following entries to your /etc/hosts file or the equivalent for your
  operating system:
```
192.168.50.2    loadbal local.dp.la
192.168.50.6    webapp1
192.168.50.50   es
```
* Run these commands in your terminal:
```
$ cd /path/to/automation/ansible  # Replace with your actual path
$ vagrant up
$ ansible-playbook -i development -u vagrant --private-key=$HOME/.vagrant.d/insecure_private_key playbooks/package_upgrade.yml dev_all.yml
$ vagrant reload
```

The various applications will be online at:

* http://local.dp.la/ (Some redirects and static resources, but not the frontend
  site)
* http://local.dp.la/pssapi/ (Primary Source Sets API)
* https://local.dp.la/primary-source-sets/admins/sign_in (Primary Source Sets
  admin. This is not served on the production site.)
* http://local.dp.la:9201/ (Elasticsearch API)
* http://webapp1:8008/munin/  (Resource monitoring graphs, after they've had
  time to gather statistics and update)

If you are having the applications go over SSL (see below), you will use
https://local.dp.la/ and https://local.dp.la:8080/v2/items.

### SSL Setup

You may set `default_http_scheme` in `ansible/group_vars/all` to control
whether your development VM's sites go over SSL. The default is `http`, which
means the development VMs will not use HTTPS.

The development VMs use a self-signed certificate, which will cause your browser
to issue a harsh security warning when you try to load `https://local.dp.la/`.
We recommend that you add the `local.dp.la` SSL certificate to your operating
system's list of trusted certificates to get around this. If you use Chrome,
the blog for the Postman utility has an article at
http://blog.getpostman.com/2014/01/28/using-self-signed-certificates-with-postman/
that provides a useful walkththrough of the steps that you can take to achieve
this. It's intended for users of Postman, which is a Chrome plugin, but will
obviously work to get Chrome to accept the certificate, which is what you need.
If you use another browser, the procedure should be similar. You need to
download the certificate and add it to your certificate chain, or your operating
system's certificate chain, with trusted status.


## Subsequent Usage

After the hosts are spooled up (as VMs or cloud servers), subsequent commands
with ansible-playbook can be run with one of the administrative user accounts
defined in the file `ansible/group_vars/all`, mentioned above.  If you're using
a VM, the "vagrant" user is necessary for initially provisioning your server,
but once the server is provisioned, and user accounts have been created, you
may use one of those sysadmin accounts for consistency with usage in
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

### SSH access

You can SSH directly into your new VMs as if they were servers on your own private
network.  For example:
```
$ ssh me@webapp1
```

## Development

### Branching and Release Model

Please see our
[Branching And Release Model](https://digitalpubliclibraryofamerica.atlassian.net/wiki/display/TECH/Branching+and+Release+Model)
wiki page.

### Application build directories

There are a number of `clean_*` variables for redeploying various
applications.  If you are deploying earlier versions of the applications and
you run into errors when they are being checked out into their build
directories, you may need to set the appropriate variable with the
`ansible-playbook` command, such as `-e 'clean_api=true'`. This can also be
useful when a switch between branches would result in a merge conflict with a
file that has been added or removed in one version or the other.

### Using local sources on your system, not from a repository

Please note that, if you're using `*_use_local_source: true` for any
application, you'll be responsible for managing the state of some of your
configuration files in your local directories, which will get deployed to the
VM. Check the roles' `tasks` files for details, or search the files for
"use_local_source" to see where this applies.

## Design considerations

Roles, inventory, and variables have been laid out to allow, as much as possible, the
use of the same roles and tasks in all stages of deployment -- development, staging,
and production.

We have considered using Docker, with its lower memory requirements.  It is
important to us, however, that we be able to simulate our networking interfaces and
their configuration, and it was not obvious that we could do that with Docker.

We will keep watching the progress of Docker support in Vagrant, and this situation
may change.   We would also like to hear from anyone who can suggest ways in which we
might use Docker, keeping in mind our need to represent our network setup.


## Tips

* The first time you create a VM, it has to do an extensive package upgrade
  of the the software in the base image, after which you should restart the VM
  with "vagrant reload".
* If you notice that your VirtualBox processes on your host computer are using a
  lot of CPU after creating new VMs, this is probably becuase the Munin resource
  monitoring tool's statistics gatherer (`munin-node`) is running endlessly.  We
  have not diagnosed what cuases this, but the easy solution is to make sure you
  have run `vagrant reload` as suggested above in Installation > Steps.
  Restarting the `munin-node` service on each host or rebooting the VMs seems to
  fix the problem.
* You probably want to exclude `$HOME/VirtualBox VMs/` from any backup jobs that
  you have going on.  The VMs can be recreated at any time, as long as you
  aren't storing data that can't be regenerated.
* If you destroy and re-create a VM, you should delete the old public key
  from `$HOME/.ssh/known_hosts` to avoid getting an error when you run
  ansible-playbook again.  Look for the hostname in addition to its IP address.
* See the note in group_vars/all.dist about using SSH private keys for deploying
  from private GitHub repositories, if you intend to use private resources.
