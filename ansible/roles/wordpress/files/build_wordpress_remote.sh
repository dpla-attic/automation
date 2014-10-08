#!/bin/bash

# Runs as 'dpla' user

plugins_branch=${1:-master}
rsync=/usr/bin/rsync

eval `ssh-agent`
ssh-add $HOME/git_private_key

# Check out wordpress plugins and transfer into build directory.
cd $HOME
if [ -d "$HOME/wordpress-plugins" ]; then
    cd $HOME/wordpress-plugins
    git checkout $plugins_branch || exit 1
    git pull || exit 1
else
    git clone git@github.com:dpla/wordpress-plugins.git wordpress-plugins \
        || exit 1
    cd $HOME/wordpress-plugins
    git checkout $branch || exit 1
fi
$rsync -ruptoglv --delete --checksum \
    --exclude '.git' \
    $HOME/wordpress-plugins/ $HOME/wordpress/wp-content/plugins

# Check out our theme's dependency theme, "egesto", and transfer
# it into the build directory.
cd $HOME
if [ -d "$HOME/frontend-wp-egesto" ]; then
    cd $HOME/frontend-wp-egesto
    git pull || exit 1
else
    git clone git@github.com:dpla/frontend-wp-egesto.git frontend-wp-egesto \
        || exit 1
fi
$rsync -ruptoglv --delete --checksum \
    --exclude '.git' \
    $HOME/frontend-wp-egesto/ $HOME/wordpress/wp-content/themes/egesto

# Check out theme and transfer into build directory.
# So far, this only has one branch, master.
cd $HOME
if [ -d "$HOME/wordpress-theme" ]; then
    cd $HOME/wordpress-theme
    git pull || exit 1
else
    git clone git@github.com:dpla/frontend-wp-theme.git wordpress-theme \
        || exit 1
fi
$rsync -ruptoglv --delete --checksum \
    --exclude '.git' \
    $HOME/wordpress-theme/ $HOME/wordpress/wp-content/themes/berkman_custom_dpla

