#!/bin/sh
#
# Fritz dsl related functions
# 

. /etc/rc.d/efw_lib.sh
. ${UPLINK_SCRIPTS}/generic/pppd.sh

CAPICONF=/etc/fcdsl/$TYPE.conf

function fritzdsl_failure() {
    fritzdsl_stop
    failure "$1"
}

function fritzdsl_write_peer() {
    pppd_write_peer $uplink || return 1

    PEERFILE=/etc/ppp/peers/$uplink

    # add frits specific options
    echo "plugin capiplugin.so" >> $PEERFILE || return 1
    echo "sync" >> $PEERFILE || return 1
    # FIXME: controller should not be hardcoded!
    echo "controller 1" >> $PEERFILE || return 1
    echo "vpi $VPI" >> $PEERFILE || return 1
    echo "vci $VCI" >> $PEERFILE || return 1

    case "$ADSL_METHOD" in
   		
        'pppoa')
	    if [ "$ADSL_ENCAP" == "llc" ]; then
		echo "protocol adslpppoallc" >> $PEERFILE || return 1
	    else
		echo "protocol adslpppoa" >> $PEERFILE || return 1
	    fi
	    ;;
											    
	'pppoe')
    	    echo "protocol adslpppoe" >> $PEERFILE || return 1
	    ;;
										
	*)
	    log_failed "fritzdsl_start unknown method '$ADSL_METHOD'"
	    return 1
	    ;;												    
    esac

    echo "/dev/null" >> $PEERFILE || return 1
    return 0
}

function fritzdsl_start() {
    local ret=0
    if [ -z "$TYPE" ]; then
        fritzdsl_failure "fritzdsl_start no TYPE set"
    fi

    modprobe $TYPE || fritzdsl_failure
    
    if [ ! -e $CAPICONF ]; then
        fritzdsl_failure "ERROR: fritzdsl_start $CAPICONF not found"
    fi

    capiinit -c $CAPICONF || fritzdsl_failure "Could not start CAPI"
    fritzdsl_write_peer || fritzdsl_failure "Could not write peer data"
    pppd_call $uplink || fritzdsl_failure "Could not successfully call PPPD"
    return 0
}

function fritzdsl_stop() {
    pppd_kill $uplink
    return $?
}
