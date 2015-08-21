
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
An initial run to add your admin shell account to the VMs, noting the tip about
`$HOME/.ssh/known_hosts` in [README.md](README.md):
```
$ ansible-playbook -i ingestion -u vagrant \
  --private-key=$HOME/.vagrant.d/insecure_private_key dev_ingestion_all.yml \
  -t users
```
Then some more invocations to configure everything:
```
$ ansible-playbook -i ingestion -u <your username in group_vars/all> \
  playbooks/package_upgrade.yml
$ vagrant reload
$ ansible-playbook -i ingestion -u <your username in group_vars/all> \
  dev_ingestion_all.yml --extra-vars "initial_run=true"
$ vagrant reload
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

## Tips

### Heiðrún deployment

After you do a full deployment, you can deploy just the application files with
`--extra-vars "fast_deployment=true"`, in order to save time.  This is useful if
you are developing `heidrun` or `krikri` and are iterating over quick changes to the
application code, and don't need to provision or configure all of the supporting
infrastructure.

Example:
`ansible-playbook -u mb -i ingestion playbooks/deploy_ingestion_app_development.yml --extra-vars="fast_deployment=true"`

### Heiðrún deployments with Solr changes

Sometimes a Heiðrún deployment will carry along with it some Solr schema or
configuration changes.  When this happens, the Solr search index that's used
for QA will have to be deleted and re-created.  An Ansible task will be
triggered to delete the index, but you will have to re-index your repository
records yourself.  This is not automated yet, and will have to be done in the
Rails console, per this example:
https://digitalpubliclibraryofamerica.atlassian.net/wiki/display/TECH/Queue+an+Indexing

### When to use this and other DPLA project VMs

There are Vagrantfiles in the `krikri` and `heidrun` projects, too.  Why should
you use the VMs created above when there are simpler ones available for working
specifically with those projects?

This set of VMs is best when you need a reasonably accurate representation of
the whole stack as it will function in production, with mostly the same moving
parts.  If you are working on the frontend or want to see how Heiðrún and Krikri
interact with Elasticsearch, NGINX, Solr, and Marmotta, this gives you the best
picture.  This setup is best for trying things out in the console.

It is not as convenient for making quick iterative developments to the code and
re-running the test suites.  For that, you might want to go over to the
`heidrun` or `krikri` project and follow the directions in either location for
using the included Vagrantfile.
