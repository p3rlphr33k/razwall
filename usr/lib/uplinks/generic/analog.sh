#!/bin/sh
#
# Generic functions for ISDN connections
#

PEERSDIR=/etc/ppp/peers

. /etc/rc.d/efw_lib.sh

function analog_write_peer() {
    local PEERNAME="$1"

    PEERFILE="$PEERSDIR/$PEERNAME"
    pppd_write_peer $PEERNAME || return 1

    [ -z "$COMPORT" -o -z "$SPEED" ] && return 1

    cat >> $PEERFILE <<EOF
$COMPORT
$SPEED
EOF
    test $? -ne 0 && return 1

    echo "connect '/usr/sbin/chat -f /etc/ppp/chat-$PEERNAME'" >> $PEERFILE || return 1

    return 0
}

function analog_write_chat() {
    local PEERNAME="$1"
    loadSettings "${SHELL_CONFIG}/modem/settings"
    export APN MODEMTYPE ATINIT ATHANGUP ATSPEAKERON ATSPEAKEROFF ATDIAL TELEPHONE SPEED NO_CGQ
    cheetah fill --env --stdout /etc/ppp/chat.tmpl > /etc/ppp/chat-$PEERNAME
    test $? -ne 0 && return 1
    return 0
}
