#!/bin/bash

log=/tmp/certificate.log
privkey=/etc/ssl/private/local.dp.la.key.pem
cert=/etc/ssl/certs/local.dp.la.pem
subj="/CN=local.dp.la"

echo Starting at `date` > $log

if [ -f $cert ]; then
    echo "Certificate exists." >> $log
    exit 0
fi

openssl req -x509 -newkey rsa:2048 -subj $subj \
    -keyout $privkey -out /tmp/tmp.pem -days 3650 -nodes 2>&1 >> $log

if [ $? -ne 0 ]; then
    echo "Aborting." >> $log
    exit 1
fi

cat /tmp/tmp.pem $privkey > $cert

if [ $? -ne 0 ]; then
    echo "Could not write $cert" >> $log
    exit 1
fi

rm /tmp/tmp.pem

echo "Changed." | tee -a $log
