#!/bin/sh
#
# Generic functions for ISDN connections
#

PEERSDIR=/etc/ppp/peers

. /etc/rc.d/efw_lib.sh

function capi_write_peer() {
    local PEERNAME="$1"
    local SECONDS="$2"
    local NODEFAULTS="$3"

    PEERFILE="$PEERSDIR/$PEERNAME"
    pppd_write_peer $PEERNAME || return 1

    # overwrite the peerfile
    cat >> $PEERFILE <<EOF
multilink
plugin capiplugin.so
protocol hdlc
sync
number $TELEPHONE
EOF
    test $? -ne 0 && return 1

    if [ -n "$SECONDS" -a $SECONDS -gt 0 ]; then
	echo "idle $SECONDS" >> $PEERFILE || return 1
    fi

    if [ $MSN ]; then
        echo "msn $MSN" || return 1
    fi

    echo "/dev/null" >> $PEERFILE || return 1
    return 0
}
