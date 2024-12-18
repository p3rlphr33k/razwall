#!/bin/sh

MAIN=/var/efw/main/settings
HOST=/var/efw/host/settings

# host/settings has a HOSTNAME -> do not migrate
grep -q "HOSTNAME" $HOST 2>/dev/null && exit 0
[ ! -e $MAIN ] && exit 0

if [ ! -d /var/efw/host ]; then
    mkdir -p /var/efw/host
fi

grep "^\(DOMAIN\|HOST\)NAME=" $MAIN >> $HOST 2>/dev/null
grep -v "^\(DOMAIN\|HOST\)NAME=" $MAIN > ${MAIN}.tmp 2>/dev/null
mv ${MAIN}.tmp $MAIN

chown nobody.nobody $MAIN $HOST

exit 0
