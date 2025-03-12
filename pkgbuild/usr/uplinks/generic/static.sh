#!/bin/sh
#
# static related functions
#


. ${UPLINK_SCRIPTS}/generic/route.sh
. ${UPLINK_SCRIPTS}/generic/hookery.sh

function static_down() {
    local IF="$old_interface"
    if [ -z "$IF" ]; then
	return 1
    fi

    ip addr flush dev ${IF} 2>/dev/null || return 1
    ip link set ${IF} promisc off || return 1
    ip link set down dev ${IF} || return 1
    ip link set up dev ${IF} || return 1
}

function static_failure() {
    static_down
    failure "$1"
}

function static_up() {
    local IF="$interface"
    local mtu_arg=""
    local mac_arg=""
    if [ -n "${new_interface_mtu}" ]; then
	mtu_arg="mtu ${new_interface_mtu}"
    fi
    if [ -n "${new_interface_mac}" ]; then
	mac_arg="address ${new_interface_mac}"
    fi

    ip link set ${IF} down
    ip link set ${IF} promisc off
    ip link set ${IF} up $mac_arg $mtu_arg || static_failure "Could not set up interface '${IF}'"
    ip addr flush dev ${IF} 2>/dev/null
    return 0
}

function static_addr() {
    local IF="$interface"
    local APPEND="$1"
    local EXCLUDE=",$2,"

    local isAppend=0

    if [ "${APPEND}" == "append" ]; then
	isAppend=1
    fi
    

    if [ $isAppend == 0 ]; then
	ip addr flush dev ${IF} 2>/dev/null
    fi

    # set up all configured ip addresses
    local ok=0
    for ipcidr in $new_ips; do
	if [ $isAppend == 1 ]; then
	    if echo $EXCLUDE | grep -q ",$ipcidr,"; then
		continue
	    fi
	fi
	ip addr add $ipcidr brd + dev $IF
	if [ $? -ne 0 ]; then
	    log_failed "Could not assign address '${ipcidr}' to interface '${IF}'"
	else
	    ok=$(($ok + 1))
	fi
    done
    if [ $isAppend == 0 -a $ok -eq 0 ]; then
	log_failed "No ip address could be assigned to interface '${IF}'"
	return 1
    fi

    return 0
}

function static_start() {

    static_up || static_failure "Could not set up static interface"
    static_addr || static_failure "Could not assign addresses to static interface"
    route_start || static_failure "Could not set up routing"

    if [ "$wan_type" == "PPTP" ]; then
        save_uplink_settings "${uplink}" "base"
	return 0
    fi

    set_active "$uplink"
    return 0
}

function static_stop() {
    local ret=0
    route_stop
    ret=$(($ret + $?))
    static_down
    ret=$(($ret + $?))
    return $ret
}
