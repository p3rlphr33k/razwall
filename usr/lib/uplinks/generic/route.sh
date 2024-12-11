#!/bin/sh
#
# routing related functions
#

ROUTEMASK=0x7F8
ROUTE_BITS=3
START_TABLE=256

function get_mark() {
    local uplink="$1"
    [ ! -e /etc/iproute2/rt_tables ] && return
    local RT=$(grep -Ee "uplink-${uplink}$" /etc/iproute2/rt_tables | cut -d ' ' -f 1)
    dc -e "$RT $START_TABLE - 1 + 2 $ROUTE_BITS ^*p"
}

function get_netaddress() {
    local cidr="$1"
    cidrinfo.py $cidr | grep -Ee "network address" | awk '{ print $3 }'
}

function route_stop() {
    ip route flush table "uplink-${uplink}" 2>/dev/null
    for ipcidr in ${old_ips}; do
	local ip=$(echo $ipcidr | cut -d '/' -f 1)
	local bits=$(echo $ipcidr | cut -d '/' -f 2)
	local net=$(get_netaddress $ipcidr)
	ip rule del prio 200 from ${ip} table "uplink-${uplink}" 2>/dev/null
	ip rule del prio 5 to ${net}/${bits} table main 2>/dev/null
    done
    local mark=$(get_mark "$uplink")
    if [ -n "${mark}" ]; then
       ip rule del prio 199 fwmark ${mark}/${ROUTEMASK} table "uplink-${uplink}" 2>/dev/null
    fi

    return 0
}

function route_start() {
    local metric_arg=""
    if [ -n "$IF_METRIC" ]; then
	metric_arg="metric $IF_METRIC"
    fi

    netcache=","
    ip route flush table "uplink-${uplink}" 2>/dev/null
    for ipcidr in ${new_ips}; do
	local ip=$(echo $ipcidr | cut -d '/' -f 1)
	local bits=$(echo $ipcidr | cut -d '/' -f 2)
	local net=$(get_netaddress $ipcidr)

        # direct connections starting from the host with specific
        # source ip addresses to the specific uplink
	ip rule del prio 200 from ${ip} table "uplink-${uplink}" 2>/dev/null
	ip rule add prio 200 from ${ip} table "uplink-${uplink}"
	if [ $? -ne 0 ]; then
	    route_stop
	    return 1
	fi

	[ "${net}" == "None" ] && continue

	# do not insert routing information twice,
	# those inserts would fail
	echo $netcache | grep -qEe ",$net/$bits," && continue
	netcache="${netcache}${net}/${bits},"


	# removing this is necessary to make it more robust and clean up
	# also possible remaining KLIPS routes which openswan do not
	# remove
	ip route del ${net}/${bits} proto kernel src ${ip}

        # route of uplink network
	ip route replace ${net}/${bits} dev ${interface} proto kernel src ${ip}
	if [ $? -ne 0 ]; then
            route_stop
            return 1
	fi

        # rules to local uplink routes, which give them precedence to
	# custom (policy) routes
	ip rule del prio 5 to ${net}/${bits} table main 2>/dev/null
	ip rule add prio 5 to ${net}/${bits} table main
	if [ $? -ne 0 ]; then
	    route_stop
	    return 1
	fi

        # XXX: add hostroute for gateway (if it is outside the network)

        # link specific default gateway entry
	ip route add ${net}/${bits} dev ${interface} proto kernel table "uplink-${uplink}"
	if [ $? -ne 0 ]; then
            route_stop
            return 1
	fi

    done

    local mark=$(get_mark "$uplink")
    if [ -z "$mark" ]; then
        route_stop
        return 1
    fi

    # link specific return packet routing
    ip rule del prio 199 fwmark ${mark}/${ROUTEMASK} table "uplink-${uplink}" 2>/dev/null
    ip rule add prio 199 fwmark ${mark}/${ROUTEMASK} table "uplink-${uplink}"
    if [ $? -ne 0 ]; then
        route_stop
        return 1
    fi

    if [ -z "${new_routers}" ] && [ -z "${new_gateway}" ]; then
	route_stop
	failure "No gateway defined!"
	return 1
    fi

    if [ -z "${new_routers}" ]; then
	local route="ip route add default via ${new_gateway} dev ${interface} proto kernel table uplink-${uplink} src ${new_ip_address}"
	$route || $route onlink
        if [ $? -ne 0 ]; then
            route_stop
            return 1
        fi
        return 0
    fi
    for router in ${new_routers}; do
        local route="ip route add default via ${router} dev ${interface} proto kernel table uplink-${uplink} ${metric_arg} src ${new_ip_address}"
	$route || $route onlink
        if [ $? -ne 0 ]; then
            route_stop
            return 1
        fi
    done
    return 0
}
