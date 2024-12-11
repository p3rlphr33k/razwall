#!/bin/sh
#
# pppd related functions
#

. /etc/rc.d/efw_lib.sh

PAPSECRETS="/etc/ppp/pap-secrets"
CHAPSECRETS="/etc/ppp/chap-secrets"
PEERSDIR="/etc/ppp/peers"

function pppd_set_secret() {
    local USERNAME="$1"
    local PASSWORD="$2"
    local ret=0

    # check if already in papsecrets
    for SECFILE in $PAPSECRETS $CHAPSECRETS; do
        touch $SECFILE
        ret=$(($ret + $?))

        if ! grep -qEe "^\"$USERNAME\"" $SECFILE; then
            # add secret
            echo "\"$USERNAME\" * \"$PASSWORD\"" >> $SECFILE
            ret=$(($ret + $?))
        else
            # replace secret
            sed -i "s|^\"$USERNAME\".*|\"$USERNAME\" * \"$PASSWORD\"|" $SECFILE
            ret=$(($ret + $?))
        fi
    done
    return $ret
}

function pppd_write_peer() {
    local PEERNAME="$1"

    PEERFILE="$PEERSDIR/$PEERNAME"

    # create peer file for pppoa
    echo "# This file was generated automatically, please do not edit!" > $PEERFILE || return 1
    echo "linkname $uplink" >> $PEERFILE || return 1
    echo "user \"$USERNAME\"" >> $PEERFILE || return 1

    # dns
    if [ "$DNS" == "Automatic" ]; then
        echo "usepeerdns" >> $PEERFILE || return 1
    fi

    # auth
    if [ "$AUTH" == "pap" ]; then
        echo "refuse-chap" >> $PEERFILE || return 1
    fi
    if [ "$AUTH" == "chap" ]; then
        echo "refuse-pap" >> $PEERFILE || return 1
    fi

    # mtu
    if [ -n "$MTU" ]; then
        echo "mtu ${MTU}" >> $PEERFILE || return 1
    fi

    # add defaults
    deffile=${PEERSDIR}/defaults/pppd-$(lowercase ${WAN_TYPE})
    if [ -e ${deffile} ]; then
        cat ${deffile} >> $PEERFILE || return 1
    fi

    # check debugging
    if [ "$DEBUG" == "on" ]; then
        echo "debug" >> $PEERFILE || return 1
    fi
    return 0
}

function pppd_call() {
    local PEERNAME="$1"

    if [ -z "$PEERNAME" ]; then
        echo "ERROR: pppd_call no peername set" || return 1
    fi
    if [ "$USERNAME" ]; then
        pppd_set_secret $USERNAME $PASSWORD
        if [ $? -ne 0 ]; then
            pppd_failure "$PEERNAME"
            return 1
        fi
    fi
    if [ -x /usr/local/bin/pppcall ]; then
        mkdir_p "${UPLINK_RUN}/${uplink}/"
        chown nobody:nogroup "${UPLINK_RUN}/${uplink}/"
        pppcall --fifofile "${UPLINK_RUN}/${uplink}/" $PEERNAME
    else
        pppd call $PEERNAME
    fi

    if [ $? -ne 0 ]; then
        pppd_failure "$PEERNAME"
        return 1
    fi
    if [ "$BOTHCHANNELS" = "on" ]; then
        sleep 3
        pppd call $PEERNAME
        # if second channel fails, do not disconnect
    fi
    return 0
}

function pppd_failure() {
    local PEERNAME="$1"
    pppd_kill "$PEERNAME"
}

function pppd_kill() {
    local PEERNAME="$1"
    local ret=0
    if [ -z "$PEERNAME" ]; then
        log_failed "pppd_kill no peername set"
        return 1
    fi
    ps ax | grep "pppd call $PEERNAME" | awk '{ print $1 }' | while read PID; do
        ps -p $PID &>/dev/null
        test $? -ne 0 && continue
        kill $PID 2>/dev/null
        ret=$(($ret + $?))
    done
    return $ret
}
