
UPGRADE INSTRUCTIONS

PostgreSQL has been upgraded from version 9.1 in Release 2.1.4 and earlier to
9.4 in Release 2.2.0.  This change requires an upgrade of PostgreSQL's tables.

PostgreSQL will copy table and index files when it performs the upgrade, so you
should make sure that the storage volumes that hold your tablespaces are less
than half-full.  You can delete the old files when the upgrade is finished,
as detailed below.

The upgrade will end with an error if your old system databases were created
with encodings other than UTF8, which has apparently happened within development
VMs in the `ingestion` inventory (using the Ingestion 2 playbooks).

Find out the encodings of your system databases (`postgres`, `template0` and
`template1`) by running `psql postgres -c 'show SERVER_ENCODING'` as `postgres`.
For example:

$ sudo -u postgres -i
$ psql postgres -c 'SHOW SERVER_ENCODING'

If this comes back with 'UTF8' then skip down to "Actual Upgrade Step" below.

If you see 'LATIN1', do the following.  There are other ways to reinitialize the
database, but this should be the easiest for most users. These instructions
assume that you have LATIN1 encodings in the database on `dev1`, in the
`ingestion` (Ingestion 2) inventory, because this is the only place where we've
observed this issue.

Option 1:

Just destroy your VM and recreate it with version 2.2.0 (`vagrant destroy dev1`,
`vagrant up dev1`), carefully following the instructions in README-ingestion2.md
after "An initial run to add your admin shell," and making sure to run the
command to configure the locale.  This is best if you don't have anything in
your application databases that you want to keep.

Option 2:

Destroy and recreate your dev1 VM, as above, but back up your application
databases first, and restore them afterwards.  The application databases do
not present any encoding problems.

1. Back up your application databases (api, dpla_portal, ingestion, marmotta,
   and pss) with pg_dump as the `postgres` account.  For example, `sudo -u
   postgres -i` and then `pg_dump -c api > /tmp/api.sql`

2. Move these backups to `/vagrant` so they will survive the destruction of the
   VM in the next step.  For example, `sudo mv /tmp/api.sql /vagrant` as your
   user account.

3. Log out of your VM, and run `vagrant destroy dev1`.
   Then run `vagrant up dev1`.

4. Follow the instructions in `README-ingestion2.md` carefully, after "An
   initial run to add your admin shell."  You must be sure to run the step that
   sets the server's locale so that PostgreSQL creates system tables in the UTF8
   encoding.

5. Log in to `dev1` and `sudo -u postgres -i`.  Restore your databases by
   running commands like `psql api < /vagrant/api.sql`.

At this point, you will be finished, after having taken either Option 1 or 2.
There will be no need to run the upgrade playbook as described below.


Actual Upgrade Step:

Run the following from your `automation/ansible` directory.  The 'purge'
variable is probably what you want in development, to save disk space, usage
by PostgreSQL being doubled without it.  If you do not specify it, the old
PostgreSQL 9.1 software installation and database files will be left on the
filesystem, and you can roll back to 9.1 per "ROLLING BACK" below.

$ ansible-playbook -u <your account on VM> -i <inventory> \
  playbooks/migrations/upgrade-postgresql-201510.yml \
  -e 'level=development purge=true'

... Where <inventory> is `development` or `ingestion`, depending on which VMs
you are using.


Post Upgrade:

If you have tablespaces outside of the default (`pg_default`), then you will end
up with data directories left over from the old version.  For example, if I have
a tablespace `marmotta_1` in `/v2/marmotta_1`, it might contain two directories,
`PG_9.1_201105231` and `PG_9.4_201409291`.  At this point, it is safe for me to
delete the old `PG_9.1_201105231` directory, because it's doubling my disk
usage for that tablespace.

If you specified `purge=false` above, you will need to manually remove the old
PostgreSQL 9.1 packages, as well as the data directory in
`/var/lib/postgresql/9.1`.


ROLLING BACK

To go back to PostgreSQL 9.1:

  First run the pg_maintenance_on.yml playbook if you're not in a development
  environment.  Then on the server ...

  $ sudo service postgresql stop
  $ mv /usr/lib/postgresql/9.4/bin/pg_ctl_disabled \
    /usr/lib/postgresql/9.4/bin/pg_ctl
  $ mv /usr/lib/postgresql/9.1/bin/pg_ctl \
    /usr/lib/postgresql/9.1/bin/pg_ctl_disabled
  $ sudo service postgresql start

  ... And run pg_maintenance_off.yml if you turned maintenance mode on above.

If you do this, you will have to use an older commit or release of `automation`
to perform future configuration, since this release assumes version 9.4.

Note that if you destroyed your dev1 VM and recreated it, as discussed above,
the way to roll back will be to revert `automation` to the version 2.1.4 tag,
and recreate and provision dev1.
