
# DPLA Automation

[![Build Status](https://travis-ci.org/dpla/automation.svg?branch=master)](https://travis-ci.org/dpla/automation)

The intention of this project is to provide automated configuration management
for production, development, and staging environments with the same set of
files.

## Version 3

[Release Notes](https://github.com/dpla/automation/releases)

Release 3.0 adds SSL support and introduces a variable (`siteproxy_port`) that
must be present in `ansible/group_vars/all`; and which will need to be added if
you are upgrading from an earlier version. See
[README-upgrade-3.0](README-upgrade-3.0.md).

Earlier versions' upgrade notes:

* [README-upgrade-2.2.0.txt](README-upgrade-2.2.0.txt)
* [README-upgrade-2.0.txt](README-upgrade-2.0.txt)

Release 2.2.0 upgraded PostgreSQL from 9.1 to 9.4.  If you have an installation
that predates [Release 2.2.0](https://github.com/dpla/automation/releases),
please see [the 2.2.0 upgrade document](README-upgrade-2.2.0.txt) now.


## Installation, VM setup:

### Prerequisites and Dependencies

At least when running all of the web application and database services together,
which is the case with the default Vagrantfile mentioned below, we assume a host
machine with at least 8 GB of memory.

Please install the following tools as documented on their websites:

* [VirtualBox](https://www.virtualbox.org/) (Version 4.3)
* [Vagrant](http://www.vagrantup.com/) (Version 1.6)
* [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest/) (`vagrant plugin install vagrant-vbguest`)
* [Ansible](http://www.ansible.com/) (Version 1.9) [installation instructions](http://docs.ansible.com/intro_installation.html)
* Additional dependencies described in the `pip` requirements file (see below)

### Steps

If you want to work with our new Ingestion2 system, please see
[README-ingestion2.md](README-ingestion2.md).

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
* Copy `Vagrantfile.dist` to `Vagrantfile`.
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

* An initial run to add your admin shell account to the VMs:
```
$ ansible-playbook -i development -u vagrant \
  --private-key=$HOME/.vagrant.d/insecure_private_key dev_all.yml \
  -t users
```
(Note that if you have a Vagrantfile from prior to
[June 2, 2015](https://github.com/dpla/automation/commit/ff515b975768da9f3e99e5caa74f6dd87d075589) and are
rebuilding your VMs, you may need to add `config.ssh.insert_key = false`.)

* Then some more invocations to configure everything:
```
$ ansible-playbook -i development -u <your username in group_vars/all> \
  playbooks/package_upgrade.yml
$ vagrant reload
$ ansible-playbook -i development -u <your username in group_vars/all> \
  dev_all.yml --extra-vars "initial_run=true"
$ vagrant reload
```

The various sites will be online at:

* http://local.dp.la/ (the frontend and WordPress)
* http://local.dp.la/exhibitions/ (the Exhibitions site)
* http://local.dp.la:8080/v2/items (the API)
* http://webapp1:8008/munin/  (resource monitoring graphs)

If you are having the applications go over SSL (see below), you will use
https://local.dp.la/, https://local.dp.la/exhibitions/, and
https://local.dp.la:8080/v2/items.

There won't be any data ingested until you run an ingestion with
[the ingestion system](http://github.com/dpla/ingestion) and you've pointed
it at the BigCouch instance, which will be loadbal:5984.

You may use the following command to initialize new repositories:

```
$ ansible-playbook -i development -u <your username> playbooks/init_index_and_repos.yml --extra-vars "level=development create_test_account=true"
```

That command deletes and re-creates the BigCouch repositories and ElasticSearch
search index, which is good for development purposes, but use it with care,
because it does delete everything.  See the comments in the top of
`init_index_and_repos.yml`.

You'll also want to become familiar with the `rake` tasks in
[the API ("platform") app](http://github.com/dpla/platform) to set up the
ElasticSearch search index and initialize your repositories.  Please consult
those other projects for more information.  There's a playbook for an
ingestion server that's not implemented yet in the development VMs.


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

#### Upgrading from before Version 3

See the "Legacy / Pre-Ingestion 2 VMs" section of
[README-upgrade-3.0](README-upgrade-3.0.md)

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

### SSH access

You can SSH directly into your new VMs as if they were servers on your own private
network.  For example:
```
$ ssh me@webapp1
```

### Suggested development workflow

Here's an example with the API app.  The process would be similiar for the frontend
app.

1. Configure ansible/roles/vars/development.yml with `api_use_local_source: true`
   and have a `webapp.vm.synced_folder` entry in your `Vagrantfile` for your
   local working copy of the project.
2. Make your changes to the local working copy.
3. In a shell (assuming you're in the directory with `ansible.cfg`):
```
$ ansible-playbook -u <your username> -i development \
  playbooks/deploy_api_development.yml
```

Repeat 2 and 3.

Please note that, if you're using `*_use_local_source: true` for any
application, you'll be responsible for managing the state of your configuration
files in your local directories, which will get deployed to the VM.  Variables
will not be substituted, e.g. for database users and passwords.  This is a
feature, to let you experiment with changes to those files.

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
