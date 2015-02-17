
# Ingestion2 development environment

This is an interim configuration until the current "ingestion2" system hits production
and we do away with the old one.  When that happens, we will be able to get rid of
the BigCouch installation and we can move services around again to have a dev setup with
two database servers, one webserver, and a loadbalancer.  For now, we're consolidating
everything onto two servers, `dev1` and `dev2`, to save memory.

Follow all of the steps in [README.md](README.md) up until "Copy Vagrantfile.dist to Vagrantfile."

## Steps

* Copy `Vagrantfile.ingestion2` to `Vagrantfile`

* Make sure that Vagrant has downloaded the base server image that we'll need
  for our VMs:
```
$ vagrant box add hashicorp/precise64
```
* Add the following entries to your /etc/hosts file or the equivalent for your
  operating system:
```
192.168.50.7    dev1 local.dp.la
192.168.50.8    dev2 ingestion2.local.dp.la ldp.local.dp.la
```
If you have checked out this project before, be sure that only `dev1` is aliased
to `local.dp.la`.
* Bring up the VMs in a shell:
```
$ cd /dir/with/Vagrantfile
$ vagrant up
$ cd ansible
```
An initial run to add your admin shell account to the VMs:
```
$ ansible-playbook -i ingestion -u vagrant \
  --private-key=$HOME/.vagrant.d/insecure_private_key dev_ingestion_all.yml \
  -t users
```
Then some more invocations to configure everything:
```
$ ansible-playbook -i ingestion -u <your username in group_vars/all> \
  playbooks/package_upgrade.yml
$ ansible-playbook -i ingestion -u <your username in group_vars/all> \
  dev_ingestion_all.yml --extra-vars "initial_run=true"
```

The various sites will be online at:

* http://local.dp.la/
* http://local.dp.la:8080/v2/items (the API)
* http://ingestion2.local.dp.la:8004/  (Heiðrún)
* http://ingestion2.local.dp.la:8080/manager/html (Tomcat admin interface)
* http://ingestion2.local.dp.la:8080/solr/#/ (Solr admin interface)
* http://ldp.local.dp.la/ (Marmotta admin interface)


There won't be any data ingested until you run an ingestion.

See the rest of the main [README.md](README.md) file for more information.
