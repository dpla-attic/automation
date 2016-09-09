#!/bin/bash

# Usage:
# ---
# Example:  certificate.sh local.dp.la
#   or      certificate.sh local.dp.la dhparam
#
# Specifying "dhparam" makes it take a long time to generate a dhprarm.pem
# file -- see below. This may be useful in the future, but we don't use it
# yet.

log=/tmp/certificate.log
privkey=/etc/ssl/private/$1.key.pem
cert=/etc/ssl/certs/$1.pem
subj="/CN=$1"
dhparam=${2:-no}
echo Starting at `date` > $log

if [ -f $cert ] && [ -f $privkey ]; then
    echo "Certificate exists." >> $log
    exit 0
fi

openssl req -x509 -newkey rsa:2048 -subj $subj \
    -keyout $privkey -out /tmp/tmp.pem -days 3650 -nodes 2>&1 >> $log

if [ $? -ne 0 ]; then
    echo "Aborting due to openssl req error!" >> $log
    exit 1
fi

cat /tmp/tmp.pem $privkey > $cert || exit 1

rm /tmp/tmp.pem || exit 1

# Supply stronger Ephemeral Diffie-Hellman parameters than openssl provides
# to nginx or haproxy by default.
# See also roles/site_proxy/templates/etc_nginx_sites_available_site-proxy.j2
if [ $dhparam -eq "dhparam" ]; then
    openssl dhparam -out /etc/ssl/dhparam.pem 4096 2>&1 >> $log
    if [ $? -ne 0 ]; then
        echo "Aborting due to openssl dhparam error!" >> $log
        exit 1
    fi
fi

echo "Changed." | tee -a $log
