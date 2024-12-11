#
# Retrieve adsl uplink information
#

. /etc/rc.d/efw_lib.sh

function adsl_get_info() {
    #
    # Returns info about the adsl connection
    #

    if [ "$1" ]; then
        local uplink=$1
    fi
    
    # for debugging purposes only
    if [ "$2" ]; then
	local suffix=".$2"
	if [ ! -f $UPLINK_ETC/$uplink/settings ]; then
	    log_failed "adsl_get_info settings file not found"
	    return
	fi
	loadSettings "$UPLINK_ETC/$uplink/settings${suffix}"
    fi

    if [ "$PROTOCOL" == "RFC2364" ]; then
        # PPPoA
	echo "rfc2364"
	echo "pppoa"
	echo "ppp"
	if [ "$ENCAP" == "0" ]; then
	    echo "vc-mux"
	else
	    echo "llc"
	fi
    elif [ "$PROTOCOL" == "RFC1483" ]; then
	echo "rfc1483"
	if [ "$METHOD" == "PPPOE" -o "$METHOD" == "PPPOE_PLUGIN" ]; then
	    # PPPoE
            echo "pppoe"
	    echo "bridged"
	    if [ "$ENCAP" == "0" ]; then
		echo "vc-mux"
	    else
		echo "llc"
            fi
	else
	    # RFC1483
            case "$METHOD" in
                "STATIC")
                    echo "static"
                    ;;
                "DHCP")
                    echo "dhcp"
                    ;;
                *)
                    echo "unknown"
                    ;;
            esac           

	    case "$ENCAP" in
		"0")
		    echo "bridged"
		    echo "vc-mux"
		    ;;
		"1")
		    echo "bridged"
		    echo "llc"
		    ;;
		"2")
		    echo "routed"
		    echo "vc-mux"
		    ;;
		"3")
		    echo "routed"
		    echo "llc"
             esac
	fi
    fi

    # FIXME: controller number should not be hardcoded
    echo "0"
}

function adsl_get_protocol() {
     adsl_get_info $1 | head -1
}

function adsl_get_method() {
     adsl_get_info $1 | head -2 | tail -1
}

function adsl_get_type() {
     adsl_get_info $1 | head -3 | tail -1
}

function adsl_get_encap() {
     adsl_get_info $1 | head -4 | tail -1
}

function adsl_get_controller() {
     adsl_get_info $1 | head -5 | tail -1
}
