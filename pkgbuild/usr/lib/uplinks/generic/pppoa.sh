#!/bin/sh
#
# Generic functions for pppoa connections
#

PEERSDIR=/etc/ppp/peers

. /etc/rc.d/efw_lib.sh
. ${UPLINK_SCRIPTS}/generic/pppd.sh
. ${UPLINK_SCRIPTS}/generic/adsl.sh

function pppoa_write_peer() {
    local PEERNAME="$1"

    PEERFILE="$PEERSDIR/$PEERNAME"

    pppd_write_peer $PEERNAME || return 1

    # add pppoa related options
    echo "plugin pppoatm.so" >> $PEERFILE || return 1
    echo "$VPI.$VCI" >> $PEERFILE || return 1

    if [ $(adsl_get_encap $uplink)  == "vc-mux" ]; then
	echo "vc-encaps" >> $PEERFILE || return 1
    else
	echo "llc-encaps" >> $PEERFILE || return 1
    fi
    return 0
}

function pppoa_init() {
    modprobe ppp_generic || failure "Could not load pppoa modules"
    modprobe pppoatm || failure "Could not load pppoa modules"
}
