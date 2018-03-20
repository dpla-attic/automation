
# UPGRADING TO RELEASE 6

If you are upgrading from a pre-version-6 version of `automation` you should
destroy your old VMs with `vagrant destroy` and start from scratch, following
the instructions in `README.md`. Enough has changed that using old VMs will
produce a faulty simulation of our current architecture.

You may keep your existing `group_vars/all` and `group_vars/development` files
as they are, and just re-run the `vagrant` commands and the Ansible playbooks.
