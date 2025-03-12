#!/bin/sh
#
# dhcp related functions
#

. ${UPLINK_SCRIPTS}/generic/static.sh
. ${UPLINK_SCRIPTS}/generic/route.sh

function dhcp_failure() {
    dhcp_stop
}

function dhcp_start() {
    iptables -D REDINPUT -p tcp --source-port 67 --destination-port 68 -i $interface -j ACCEPT &>/dev/null
    iptables -A REDINPUT -p tcp --source-port 67 --destination-port 68 -i $interface -j ACCEPT
    if [ $? -ne 0 ]; then
        dhcp_failure "Could not add DHCP iptables rules"
        return 1
    fi
    iptables -D REDINPUT -p udp --source-port 67 --destination-port 68 -i $interface -j ACCEPT &>/dev/null
    iptables -A REDINPUT -p udp --source-port 67 --destination-port 68 -i $interface -j ACCEPT
    if [ $? -ne 0 ]; then
        dhcp_failure "Could not add DHCP iptables rules"
        return 1
    fi

    dhclient -1 -pf /var/run/dhclient.${interface}.pid \
	     -lf /var/lib/dhclient/dhclient.${interface}.leases \
	     -sf /sbin/dhclient-efw-script \
	     ${interface}
    if [ $? -ne 0 ]; then
        dhcp_failure "Could not successfully start dhclient"
        return 1
    fi
}

function dhcp_kill() {
    local interface="$1"
    local ret=0

    [ ! -e /var/run/dhclient.${interface}.pid ] && return $ret
    kill -TERM $(cat /var/run/dhclient.${interface}.pid) 2>/dev/null
    ret=$(($ret + $?))
    rm -f /var/lib/dhclient/dhclient.${interface}.info 2>/dev/null
    return $ret
}

function dhcp_stop() {
    local ret=0

    dhcp_kill $old_interface
    ret=$(($ret + $?))
    route_stop
    ret=$(($ret + $?))
    static_down
    ret=$(($ret + $?))

    iptables -D REDINPUT -p tcp --source-port 67 --destination-port 68 -i $old_interface -j ACCEPT 2>/dev/null
    ret=$(($ret + $?))
    iptables -D REDINPUT -p udp --source-port 67 --destination-port 68 -i $old_interface -j ACCEPT 2>/dev/null
    ret=$(($ret + $?))

    return $ret
}
