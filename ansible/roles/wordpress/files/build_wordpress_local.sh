#!/bin/bash

# Runs as 'dpla' user

rsync=/usr/bin/rsync

# Copy local plugins directory into build directory
$rsync -ruptl --checksum --delete --delay-updates \
    --exclude '.git'
    /wordpress-plugins/ /home/dpla/wordpress/wp-content/plugins

# Copy themes directory into build directory
$rsync -ruptl --checksum --delete --delay-updates \
    --exclude '.git'
    /wordpress-theme/ \
    /home/dpla/wordpress/wp-content/themes/berkman_custom_dpla

# Check our our theme's dependency, "egesto".  It does not seem
# worth it to have this pulled in from a local directory, so it's
# pulled from a private repository.
eval `ssh-agent`
ssh-add $HOME/git_private_key
if [ -d "$HOME/frontend-wp-egesto" ]; then
    cd $HOME/frontend-wp-egesto
    git pull || exit 1
else
    cd $HOME
    git clone git@github.com:dpla/frontend-wp-egesto.git frontend-wp-egesto \
        || exit 1
fi
$rsync -ruptoglv --delete --checksum \
    --exclude '.git' \
    $HOME/frontend-wp-egesto/ $HOME/wordpress/wp-content/themes/egesto
