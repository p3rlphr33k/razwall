#!/bin/sh
#
# Generic functions for pptp connections
#

PEERSDIR=/etc/ppp/peers

. /etc/rc.d/efw_lib.sh
. ${UPLINK_SCRIPTS}/generic/pppd.sh

function pptp_write_peer() {
    local PEERNAME="$1"
    local ROUTER_IP="$2"

    if [ -z "$ROUTER_IP" ]; then
	log_failed "ppptp_write_peer needs a router ip as second arg!"
	return 1
    fi

    PEERFILE="$PEERSDIR/$PEERNAME"

    pppd_write_peer $PEERNAME || return 1

    # add pptp related options
    pptpargs=""
    if [ -n "$PHONENUMBER" ]; then
	pptpargs="$pptpargs --phone $PHONENUMBER"
    fi
    if [ "$DEBUG" == 'on' ]; then
	pptpargs="$pptpargs --loglevel 2"
    fi
    echo "pty '/usr/sbin/pptp $ROUTER_IP --nobuffer --nolaunchpppd --sync --logstring pptp $pptpargs'" >> $PEERFILE || return 1
    return 0
}

function pptp_failure() {
    pptp_stop "$1"
    return 1
}

function pptp_kill() {
    local PEERNAME="$1"
    local PIDFILE="/var/run/pptp-{PEERNAME}.pid"
    local PID=$(cat ${PIDFILE} 2>/dev/null)
    ps -p $PID &>/dev/null
    test $? -ne 0 && return
    kill $PID 2>/dev/null
    return $?
}

function pptp_stop() {
    local PEERNAME="$1"
    local ret=0

    pptp_kill "$PEERNAME"
    ret=$(($ret + $?))
    pppd_kill "$PEERNAME"
    ret=$(($ret + $?))

    return $ret
}

function pptp_call() {
    if [ -z "$1" ]; then
        PEERNAME=$uplink
    else
        PEERNAME=$1
    fi

    pppd_call $PEERNAME || pptp_failure "$PEERNAME" "Could not successfully call pptp"
    return $?
}

function pptp_init() {
    echo &>/dev/null
}
