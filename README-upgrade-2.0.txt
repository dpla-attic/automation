
UPGRADING TO RELEASE 2.0

---

This documentation is being retained in `automation` for historical
purposes. It documents an upgrade from one obsolete version of `automation` to
another obsolete one. If you are reading this and have a version older than
2.0, we encourage you to start fresh with a new set of VMs, using the most
recent version.

---

Release 2.0 contains breaking changes that move variable definitions around.  If
you are upgrading from version 1.x, you will encounter errors related to
undefined variables if you don't follow the steps below.  Fortunately, the
upgrade process is pretty straightforward if you have a develpment environment
without a lot of customization.

The new version 2 way of doing things

    The main change in version 2 is that variables are handled in a more
    Ansible-orthodox way, taking advantages of Ansible's variable precedence
    rules.  We're defining variables that override role defaults in `group_vars`
    files.

    The inventory file has been changed to define inventory groups that go from
    most general (the deployment environment, like "development") to most
    specific (for example, the group name corresponding with a role, like
    "postgresql_dbs", or even more specific, like "webapps").  See the
    `development' and `ingestion' inventory files, noting, for example, how the
    `development_ingestion2` group is more specific than `development`.  This
    fixes some problems with overriding variables that were present in
    version 1.

    There should be fewer files and variables to maintain overall, after the
    initial changes necessitated by upgrading.

Step 1.  Back up your `automation' directory.

    Back up your `automation' directory before proceeding.  You will probably
    want it for reference in case there's any question about variables that
    you've copied in the following steps, or in case there's any problem.

    Suggestions:
        *nix in general with rsync: `rsync -a automation/ automation.backup'
        OS X:  `ditto automation automation.backup'

Step 2.  Update your `automation' directory.

    Use `git pull' or whatever other means (e.g. zipfile download from GitHub)
    to update your `automation' directory with version 2.  If you're tracking
    `development' or `master', this just means doing a `git pull'.

Step 3.  Replace `group_vars/all`

    Back up your `group_vars/all` file and copy the new `group_vars/all.dist`
    into place (for a typical development environment).

    The way to get the cleanest cascade of variable definitions is to spend a
    minute or two to look at each variable in your new `group_vars/all` file and
    redefine any that you had set differently in your backed-up version
    (especially `adminusers' and anything that says "CHANGEME").  Look at
    `vars/development.yml' and `roles/*/vars/development.yml'.

Step 4.  Remove old files in roles' `vars' directories.

    You have, of course, backed up your `automation' directory so that this is
    not going to cause any permanent trouble.  :-)

    Remove the deployment-environment ("level") variable files in
    `roles/*/vars`.  The version 2 way of defining these is to override them in
    `group_vars' files named after the environment, such as
    `group_vars/development` or `group_vars/development_ingestion2`.

    If you have any values in a `development.yml` file that differ from the
    role's defaults (see `<role>/defaults/main.yml`) then make sure it's copied
    to `group_vars/development` or `group_vars/development_ingestion2`.
    Otherwise, don't worry about it; just delete the file.

    Be sure not to remove any `main.yml' files.

Step 5.  Change variable declarations for variables that have been renamed.

    If you had any of the following variables defined in any `development.yml'
    files, note that they have been renamed in version 2, so you'll have to make
    sure they're correct in your `group_vars' files.  They all have defaults
    that seem to be good for the development VMs, so you can probably just
    remove them or avoid copying them to your `group_vars' files.

    admin_pwhash -> marmotta_admin_pwhash
    apt_cache_valid_time -> elasticsearch_apt_cache_valid_time
    backups_basedir -> *_backups_basedir for postgresql and mysql
    heidrun_allowed_ip -> marmotta_heidrun_allowed_ip
    log_rotation_count -> pg_log_rotation_count
    log_rotation_count -> pg_log_rotation_count
    log_rotation_interval -> pg_log_rotation_interval
    log_rotation_interval -> pg_log_rotation_interval
    nginx_bookshelf_conn_zone_size -> siteproxy_bookshelf_conn_zone_size
    nginx_bookshelf_max_conn -> siteproxy_bookshelf_max_conn
    nginx_bookshelf_req_rate -> siteproxy_bookshelf_req_rate
    nginx_bookshelf_req_zone_size -> siteproxy_bookshelf_req_zone_size
    nginx_conn_zone_size -> siteproxy_nginx_conn_zone_size
    nginx_default_max_conn -> siteproxy_nginx_default_max_conn
    nginx_default_req_burst_size -> siteproxy_nginx_default_req_burst
    nginx_default_req_rate -> siteproxy_nginx_default_req_rate
    nginx_limit_conn_log_level -> siteproxy_nginx_limit_conn_log_level
    nginx_limit_req_log_level -> siteproxy_nginx_limit_req_log_level
    nginx_req_zone_size -> siteproxy_nginx_req_zone_size
    rails_env -> various *_rails_env per role
    ruby_rbenv_version -> various *_rbenv_versions per role
    unicorn_worker_processes -> various *_unicorn_worker_processes per role

    Please note that the variable `ruby_rbenv_version' has been removed, and is
    superceded by various role-specific variables.

    These variables were renamed to allow them to exist at the `group_vars'
    level.

Step 6.  Test

    Run `git status' to see if any files are reported as untracked.  These may
    be files that you want to remove.

    Run `ansible-playbook' with `-C -D' against a VM that you know is up-to-date
    and that you've successfully used with version 1.  `-C' performs a dry run
    and `-D' displays a diff of any changes that Ansible would make to files.
    This is a great way to spot variables that have been misdefined; or that are
    undefined, in which case they'll probably trigger errors.

