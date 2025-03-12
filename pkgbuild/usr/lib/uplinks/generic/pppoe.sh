#!/bin/sh
#
# Generic functions for pppoe connections
#

PEERSDIR=/etc/ppp/peers

. /etc/rc.d/efw_lib.sh
. ${UPLINK_SCRIPTS}/generic/pppd.sh

function pppoe_write_peer() {
    local PEERNAME="$1"
    local PPPOEDEV="$2"
    
    if [ -z "$PPPOEDEV" ]; then
	log_failed "pppoe_write_peer needs a device name as second arg!"
	return 1
    fi
    
    PEERFILE="$PEERSDIR/$PEERNAME"

    pppd_write_peer $PEERNAME || return 1

    # run pppoe
    echo "plugin rp-pppoe.so $PPPOEDEV" >> $PEERFILE

    # add pppoe related options
    if [ "$SERVICENAME" ]; then
       echo "rp_pppoe_service \"$SERVICENAME\"" >> $PEERFILE
    fi

    if [ "$CONCENTRATORNAME" ]; then
       echo "rp_pppoe_ac \"$CONCENTRATORNAME\"" >> $PEERFILE
    fi

    return 0
}

function pppoe_failure() {
    pppoe_stop "$1" "$2"
    failure "$3"
}

function pppoe_kill() {
    local PEERNAME="$1"
    local PIDFILE="/var/run/pppoe-{PEERNAME}.pid"
    local PID=$(cat ${PIDFILE} 2>/dev/null)
    ps -p $PID &>/dev/null
    test $? -ne 0 && return
    kill $PID 2>/dev/null
    return $?
}

function pppoe_stop() {
    local PEERNAME="$1"
    local PPPOEDEV="$2"
    local ret=0

    pppd_kill "$PEERNAME"

    ret=$(($ret + $?))

    ip addr flush dev $PPPOEDEV 2> /dev/null
    ret=$(($ret + $?))
    ip link set $PPPOEDEV down 2> /dev/null
    ret=$(($ret + $?))
    return $ret
}

function pppoe_call() {
    if [ -z "$1" ]; then
        PEERNAME=$uplink
    else
        PEERNAME=$1
    fi

    if [ -z "$2" ]; then
        pppoe_failure "-" "-" "pppoe_call needs a device as second argument"
    else
        PPPOEDEV=$2
    fi

    ifconfig $PPPOEDEV 1.1.1.1 netmask 255.255.255.0 broadcast 1.1.1.255 up 2> /dev/null
    # check if ifconfig was successfull
    if [ $? -ne 0 ]; then
        pppoe_failure "$PEERNAME" "$PPPOEDEV" "pppoe_call unable to setup device $PPPOEDEV"
    fi

    pppd_call $PEERNAME || pppoe_failure "$PEERNAME" "$PPPOEDEV" "Could not successfully call pppd"
    return 0
}

function pppoe_init() {
    modprobe ppp_generic || failure "Could not load pppoe modules"
    modprobe pppoe || failure "Could not load pppoe modules"
}
