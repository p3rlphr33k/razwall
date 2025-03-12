#!/bin/sh

. /etc/rc.d/efw_lib.sh
. ${UPLINK_SCRIPTS}/generic/adsl.sh
. ${UPLINK_SCRIPTS}/generic/hookery.sh
. ${UPLINK_SCRIPTS}/generic/static.sh

function get_interface() {
    local ADSL_TYPE="$1"

    # starts a routed atm interface
    IFACENUM=$(adsl_get_controller $uplink)

    if [ -z "$IFACENUM" ]; then
	echo "error"
	return
    fi

    export IFACENUM

    local IFACE=""

    case "$ADSL_TYPE" in
	'routed')
	    IFACE="atm"
	    ;;
	'bridged')
	    IFACE="nas"
	    ;;
	*)
	    echo "error"
	    return
	    ;;
    esac

    echo ${IFACE}${IFACENUM}
}

function rfc1483_if_start() {
    interface=$(get_interface $ADSL_TYPE)
    export IFACENUM=$(adsl_get_controller $uplink)

    if [ "$interface" == "error" ]; then
	failure "Could not determine interface for uplink '$uplink'"
    fi
    export interface

    case "$ADSL_TYPE" in
	'routed')
	    rfc1483_routed_start || failure
            ;;
	'bridged')
	    rfc1483_bridged_start || failure
	    ;;
	*)
	    failure "adsl_type $ADSL_TYPE unknown"
	    ;;
    esac
    set_active "$uplink"
    return 0
}

function rfc1483_if_stop() {
    old_interface=$(get_interface $ADSL_TYPE)
    if [ "$old_interface" == "error" ]; then
	log_failed "Could not determine interface for uplink '$uplink'"
	return 1
    fi
    export old_interface

    case "$ADSL_TYPE" in
	'routed')
	    rfc1483_routed_stop || return 1
	    ;;
	'bridged')
	    rfc1483_bridged_stop || return 1
	    ;;
	*)
	    log_failed "adsl_type $ADSL_TYPE unknown"
	    return 1
	    ;;
    esac
}

function rfc1483_failure() {
    rfc1483_if_stop
    failure "$*"
}

function rfc1483_routed_start() {
    modprobe pppoatm || rfc1483_failure "Could not load rfc1483 modules"
    # run atm arpd if it isn't already running
    if ! ps -ef | grep -Eqe "[a]tmarpd" > /dev/null 2>&1; then
	atmarpd -b  -l syslog > /dev/null 2>&1 || rfc1483_failure "Could not start atmarpd for uplink '$uplink'"
	sleep 3
    fi

    # check if device was already configured"
    if ! ip link show $interface > /dev/null 2>&1; then
	atmarp -c $interface || rfc1483_failure "Could not start atmarp with interface '$interface' for uplink '$uplink'"
    fi

    # we need some time to settle up
    sleep 3

    local mtu_arg=""
    if [ -n "${new_interface_mtu}" ]; then
        mtu_arg="mtu ${new_interface_mtu}"
    fi

    static_addr || rfc1483_failure "Could not configure ip addresses to interface '$interface' in uplink '$uplink'"
    ip link set $interface up $mtu_arg> /dev/null 2>&1 || rfc1483_failure "Could not bring up interface '$interface' in uplink '$uplink'"

    # we need some time to settle up
    sleep 2

    # set gateway of device
    if ! atmarp -s $GATEWAY $IFACENUM.$VPI.$VCI > /dev/null 2>&1; then
        rfc1483_failure "Could not set arp gateway in uplink '$uplink'"
    fi

    return 0
}

function rfc1483_routed_stop() {
    # shutdown the interface
    killall atmarpd
    ip addr flush dev $old_interface
    ip link set $old_interface down || return 1
}

function rfc1483_bridged_start() {
    # starts a brided nas interface
    modprobe br2684 || rfc1483_failure "Could not load rfc1483 modules"

    if [ $(adsl_get_encap $uplink)  == "vc-mux" ]; then
	IFENCAP="1"
    else
	IFENCAP="0"
    fi
 
    br2684ctl -b -c $IFACENUM -e $IFENCAP -a $IFACENUM.$VPI.$VCI > /dev/null 2>&1 || \
	rfc1483_failure "could not create bridge in uplink '$uplink'"

    sleep 3
    ip link set $interface up || \
	rfc1483_failure "could not set up interface '$interface' for uplink '$uplink'"
    return 0
}

function rfc1483_bridged_stop() {
    local ret=0
    ip link set $old_interface down 2>/dev/null
    ret=$(($ret + $?))

    killall br2684ctl
    ps axw | grep -Ee "br2684ctl.*\-c $IFACENUM " | awk '{ print $1 }' | while read PID; do
        ps -p $PID &>/dev/null
        test $? -ne 0 && continue
        kill $PID 2>/dev/null
        ret=$(($ret + $?))
    done
    return $ret
}
