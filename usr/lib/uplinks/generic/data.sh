#!/bin/sh
#
# data related information
#

#
#        +-----------------------------------------------------------------------------+
#        | RazWall Firewall - 2024                                                     |
#        | www.RazWall.com		                                                       |
#        +-----------------------------------------------------------------------------+
#

function export_old_uplink_values() {
    local uplink="$1"
    local datafile="$2"
    export_uplink_settings "${uplink}"

    loadSettings ${UPLINK_VAR}/${uplink}/${datafile}.old
    loadSettings ${UPLINK_VAR}/${uplink}/settings.old
    loadSettings ${UPLINK_ETC}/${uplink}/settings

    [ -z "$gateway" ] && gateway=$new_gateway
    [ -z "$broadcast_address" ] && broadcast_address=$new_broadcast_address
    [ -z "$network_number" ] && network_number=$new_network_number
    [ -z "$cidr" ] && cidr=$new_cidr
    [ -z "$ip_address" ] && ip_address=$new_ip_address
    [ -z "$ips" ] && ips=$new_ips
    [ -z "$domain_name_servers" ] && domain_name_servers=$new_domain_name_servers
    [ -z "$wan_type" ] && wan_type=$WAN_TYPE
    [ -z "$interface_mtu" ] && interface_mtu=$new_interface_mtu
    [ -z "$interface_mac" ] && interface_mac=$new_interface_mac

    export old_interface=$interface
    export old_gateway=$gateway
    export old_broadcast_address=$broadcast_address
    export old_network_number=$network_number
    export old_cidr=$cidr
    export old_ip_address=$ip_address
    export old_ips=$ips
    export old_domain_name_servers=$domain_name_servers
    export old_wan_type=$wan_type
    export old_interface_mtu=$interface_mtu
    export old_interface_mac=$interface_mac
}

function save_uplink_settings() {
    local uplink="$1"
    local datafile="${2:-data}"
    mkdir_p "${UPLINK_VAR}/${uplink}"
    chown nobody:nogroup "${UPLINK_VAR}/${uplink}"
    cat >${UPLINK_VAR}/${uplink}/${datafile} <<EOF
wan_type=$wan_type
interface=$interface
gateway=$new_gateway
broadcast_address=$new_broadcast_address
network_number=$new_network_number
cidr=$new_cidr
ip_address=$new_ip_address
ips=$new_ips
domain_name_servers=$new_domain_name_servers
interface_mac=$new_interface_mac
interface_mtu=$new_interface_mtu
EOF

    if [ -n "$bridge_port" ]; then
    cat >>${UPLINK_VAR}/${uplink}/${datafile} <<EOF
bridge_port=$bridge_port
EOF
    fi
}

function export_uplink_settings() {
    local uplink="$1"
    local myvar=""

    loadSettings ${UPLINK_ETC}/${uplink}/settings

    export interface=$WAN_DEV
    export wan_type=$WAN_TYPE

    # find gateway
    for myvar in $DEFAULT_GATEWAY $GATEWAY; do
	export new_gateway=$myvar
	break
    done

    # if this is GATEWAY uplink and default gateway need to be read
    # out from a local zone because it came from DHCP.
    if [ $WAN_TYPE == "NONE" -a -n "$GATEWAY_ZONE" ]; then
	loadSettings /var/efw/ethernet/settings
	key="\$${GATEWAY_ZONE}_GATEWAY"
	zonegw=$(eval "echo $key")
	if [ -n "$zonegw" ]; then
	    export new_gateway=$zonegw
	fi
    fi

    local legacy_wan_ip=""
    # find legacy wan ip
    for myvar in $WAN_ADDRESS $IP; do
	legacy_wan_ip=$myvar
	break
    done
    local legacy_wan_cidr=""
    # find legacy wan cidr
    for myvar in $WAN_CIDR $CIDR; do
	legacy_wan_cidr=$myvar
	break
    done
    if [ -n "$legacy_wan_ip" ] && [ -n "$legacy_wan_cidr" ]; then
        if ! echo ",$WAN_IPS," | grep -q ",$legacy_wan_ip/$legacy_wan_cidr,"; then
            WAN_IPS="$legacy_wan_ip/$legacy_wan_cidr,$WAN_IPS"
        fi
    fi

    # create aliases list
    new_ips=""
    local IFS=,
    for myvar in $WAN_IPS; do
	[ -z "$myvar" ] && continue
	new_ips="${new_ips}${myvar} "
    done
    export new_ips

    if [ -n "$new_ips" ]; then
        local mainip=$(echo $new_ips | cut -d ' ' -f 1)
        export new_network_number=$(cidrinfo.py $mainip | grep -Ee "network address" | awk '{ print $3 }')
        export new_cidr=$(echo $mainip | cut -d '/' -f 2)
        export new_ip_address=$(echo $mainip | cut -d '/' -f 1)
    fi

    export new_domain_name_servers="$DNS1 $DNS2"
    export new_interface_mtu="$MTU"
    export new_interface_mac="$MAC"
}

function init_variables() {
    uplink="$1"
    local arg="$2"
    local datafile="${3:-data}"

    export logger_tag="uplink[$uplink]"
    if [ -z "${uplink}" ]; then
	bailout "Link \"${uplink}\" not found!"
    fi
    
    if [ ! -f ${UPLINK_ETC}/${uplink}/settings ]; then
	bailout "Link \"${uplink}\" has no configuration!"
    fi

    if [ -n "$arg" -a "$arg" = "stop" -a -f ${UPLINK_VAR}/${uplink}/settings.old ]; then
	loadSettings ${UPLINK_VAR}/${uplink}/settings.old
    else
	loadSettings ${UPLINK_ETC}/${uplink}/settings
	save_old_settings ${UPLINK_ETC}/${uplink}/settings
    fi

    save_old_settings ${UPLINK_VAR}/${uplink}/${datafile}
    export uplink
    export_old_uplink_values "${uplink}" "${datafile}"
    export_uplink_settings "${uplink}"
}

