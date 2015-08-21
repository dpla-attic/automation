
# DPLA Automation

[![Build Status](https://travis-ci.org/dpla/automation.svg?branch=master)](https://travis-ci.org/dpla/automation)

The intention of this project is to provide automated configuration management
for production, development, and staging environments with the same set of
files.

[Release Notes](https://github.com/dpla/automation/releases)

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
  * `ansible/vars/development.yml.dist`
  * `ansible/roles/api/vars/development.yml.dist`
    * Optional, if you want to use a local source directory for the API app (see
      `Vagrantfile`).
  * `ansible/roles/elasticsearch/vars/development.yml.dist`
  * `ansible/roles/postgresql/vars/development.yml.dist`
  * `ansible/roles/frontend/vars/development.yml.dist`
    * Optional.  For the frontend app, as above.  See `Vagrantfile`.
* Optionally, copy and update any other `ansible/roles/*/development.yml.dist`
  files in a similar fashion.  There are defaults that will take effect if you don't
  make any changes.
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
Then some more invocations to configure everything:
```
$ ansible-playbook -i development -u <your username in group_vars/all> \
  playbooks/package_upgrade.yml
$ vagrant reload
$ ansible-playbook -i development -u <your username in group_vars/all> \
  dev_all.yml --extra-vars "initial_run=true"
$ vagrant reload
```

The various sites will be online at:

* http://local.dp.la/
* http://local.dp.la/exhibitions/
* http://local.dp.la:8080/v2/items (the API)
* http://webapp1:8004/munin/  (resource monitoring graphs)


However, there won't be any data ingested until you run an ingestion with
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

