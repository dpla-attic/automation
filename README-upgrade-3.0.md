
# UPGRADING TO RELEASE 3.0


Legacy / Pre-Ingestion 2 VMs (`development` inventory)
------------------------------------------------------

Ensure that the variable `siteproxy_port` exists in `ansible/group_vars/all`
and `ansible/group_vars/development`.
You will need to add this if you are upgrading from an earlier version. See
`ansible/group_vars/all.dist` and `development.dist`.  Its suggested value for
development is "8010".  You also need to set `monitoring_http_port`, which
we suggest you set to "8008".  Add the following two lines to your `ansible/group_vars/development` file:
```
monitoring_http_port: 8008
siteproxy_port: 8010
```

Modify your existing `es_cluster_loadbal` value in `ansible/group_vars/all` and
`ansible/group_vars/development_ingestion2` to include the port number '9201'.
For example, in `ansible/group_vars/all`:
```
es_cluster_loadbal: 192.168.50.2:9201
```
And in `ansible/group_vars/development_ingestion2`:
```
es_cluster_loadbal: 192.168.50.2:9201
```

(If you're using `automation` in a staging or production environment, you
also want to change `es_cluster_loadbal` wherever else it appears to
include the port number.)

See the new `default_http_scheme` variable in `ansible/group_vars/all.dist`.
Make sure that your `ansible/group_vars/all` file has this variable, set to your
liking.

If you are using a local-working-copy version of the `frontend` app, make sure
that it's current with `develop` branch, or has been rebased upon it.

Log in to the `loadbal` VM:
```
ssh <you>@loadbal
```

Remove the existing `haproxy` and `hatop` packages, which don't support SSL ...
```
sudo aptitude purge hatop
sudo aptitude purge haproxy
exit
```
... And run the loadbalancer role's playbook to install and configure a more
recent version of `haproxy` that supports SSL:
```
ansible-playbook -u <you> -i development playbooks/dev_loadbalancer.yml
```

If you're switching to https by modifying `default_http_scheme`, you need to
re-run your playbooks:
```
ansible-playbook -u <you> -i development dev_all.yml
```


Ingestion 2 VMs (`ingestion` inventory)
---------------------------------------

See the first paragraphs of the section above, regarding `siteproxy_port`,
`monitoring_port`, `default_http_scheme`, and `es_cluster_loadbal`, and
`default_http_scheme`.

If you are using a local-working-copy version of the `frontend` app, make sure
that it's current with `develop` branch, or has been rebased upon it.

Log in to the `dev1` VM:
```
ssh <you>@dev1
```

Remove the existing `haproxy` and `hatop` packages, which don't support SSL ...
```
sudo aptitude purge hatop
sudo aptitude purge haproxy
exit
```
... And run the loadbalancer role's playbook to install and configure a more
recent version of `haproxy` that supports SSL:
```
ansible-playbook -u <you> -i ingestion playbooks/dev_loadbalancer.yml \
    -e 'ingestion2=true'
```

If you're switching to https by modifying `default_http_scheme`, you need to
re-run your playbooks:
```
ansible-playbook -u <you> -i ingestion dev_ingestion_all.yml
```

