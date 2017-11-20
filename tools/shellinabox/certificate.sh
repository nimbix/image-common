#!/bin/bash

CERTDIR=/var/lib/shellinabox

[ -f /etc/JARVICE/jobinfo.sh ] && . /etc/JARVICE/jobinfo.sh
SERVERNAME=$(echo "$JOB_PUBLICADDR" | tr A-Z a-z)

if [ -f /etc/JARVICE/cert.pem ]; then
    if [ -n "$SERVERNAME" ]; then
        [ -f $CERTDIR/certificate-$SERVERNAME.pem ] && \
            rm -f $CERTDIR/certificate-$SERVERNAME.pem
        ln -s /etc/JARVICE/cert.pem $CERTDIR/certificate-$SERVERNAME.pem
    fi
    [ -f $CERTDIR/certificate.pem ] && rm -f $CERTDIR/certificate.pem
    ln -s /etc/JARVICE/cert.pem $CERTDIR/certificate.pem
fi

