
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2006 Endian                                              |
#        |         Endian GmbH/Srl                                                     |
#        |         Bergweg 41 Via Monte                                                |
#        |         39057 Eppan/Appiano                                                 |
#        |         ITALIEN/ITALIA                                                      |
#        |         info@endian.it                                                      |
#        |                                                                             |
#        | This program is free software; you can redistribute it and/or               |
#        | modify it under the terms of the GNU General Public License                 |
#        | as published by the Free Software Foundation; either version 2              |
#        | of the License, or (at your option) any later version.                      |
#        |                                                                             |
#        | This program is distributed in the hope that it will be useful,             |
#        | but WITHOUT ANY WARRANTY; without even the implied warranty of              |
#        | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               |
#        | GNU General Public License for more details.                                |
#        |                                                                             |
#        | You should have received a copy of the GNU General Public License           |
#        | along with this program; if not, write to the Free Software                 |
#        | Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. |
#        | http://www.fsf.org/                                                         |
#        +-----------------------------------------------------------------------------+
#

#
# Author:      Peter Warasin <peter@endian.it>
# Date:        2005-03-27
# Description: Endian Firewall library. It does contain some generic functions
#

CONFIG_ROOT=/var/efw/
INITSCRIPTS=/etc/rc.d/
LOCKFILES=/var/lock/efw
#STATE_D=/var/lib/efw/
STATE_D=/var/efw/
PERSISTENT_D=/usr/lib/efw/
USER_D=${CONFIG_ROOT}
#VOLATILE_D=/var/run/efw/
VOLATILE_D=/var/efw/
#SHELL_CONFIG=/etc/efw/
SHELL_CONFIG=/var/efw/

UPLINK_SCRIPTS=/usr/lib/uplinks/
UPLINK_DIR=${CONFIG_ROOT}/uplinks/
UPLINK_ETC=${CONFIG_ROOT}/uplinks/
UPLINK_VAR=${CONFIG_ROOT}/uplinks/
UPLINK_RUN=${CONFIG_ROOT}/uplinks/

FIREWALL=/etc/firewall/

TRUE=0
FALSE=1
function check_net() {
    local CONF="$*"
    for net in ${CONF}; do
	if [ "${CONFIG_TYPE}" == "$net" ]; then
	    return ${TRUE}
	fi
    done
    return ${FALSE}
}

function has_dmz () {
    local ORANGE="1 3 5 7";
    return $(check_net "${DMZ}")
}

function has_lan2 () {
    local LAN2="4 5 6 7";
    return $(check_net "${LAN2}")
}

function wan_is_ether () {
    local WANMODEM="2 3 6 7";
    return $(check_net "${WANMODEM}")
}

function has_dhcp () {
    # dhcp over static ethernet
    if wan_is_ether; then
	if [ "${WAN_TYPE}" == "DHCP" ]; then
	    return ${TRUE}
	fi
	return ${FALSE}
    fi

    # wan is a modem, hdcp can only be used through rfc1483 or through pptp
    if [ "${PROTOCOL}" != "RFC1483" ] && [ "${TYPE}" != "PPTP" ]; then
	return ${FALSE}
    fi
    if [ "${METHOD}" == "DHCP" ]; then
	return ${TRUE}
    fi
    return ${FALSE}
}


function wan_is_active() {
    if [ "$(wan_active_count)" -gt 0 ]; then
	return ${TRUE}
    fi
    return ${FALSE}
}

function iterate() {
    local DIR="$1"
    local PARAM="$2"
    local WAITS=0

    if [ ! -d "${DIR}" ]; then
	return
    fi
    find "${DIR}" -type f -or -type l -maxdepth 1 | while read FILE; do
	echo "$(basename ${FILE}) ${FILE}"
    done

    if [ -z "${PARAM}" ]; then
	return
    fi
    iterate "${DIR}/${PARAM}"
}

function rc_start() {
    local SUBDIR="$1"
    local PARAM="$2"
    iterate "${INITSCRIPTS}/${SUBDIR}" "${PARAM}" | sort | \
	while read PRIO FILE; do
	    ${FILE}
    done
}

# This script reads in variables from a config file, and produces a list of
# commands to run to set these as shell environment variables
function readhash() {
    local CONFIG="$1"
    # shell variables must consist of alphanumeric characters and underscores,
    # and begin with an alphabetic character or underscore.
    local VARNAME='[A-Za-z_][A-Za-z0-9_]*'
    # For the assigned value we only accept a limited number of characters - none
    # of which are shell metachars
    VARCHARS='A-Za-z0-9%=:/,._@#+-'
    VARVAL="[${VARCHARS}]*"

    sed -ne "s/^\(${VARNAME}\)=\(${VARVAL}\)$/\1=\2/p" "${CONFIG}"
    # Accept space only if it's quoted
    sed -ne "s/^\(${VARNAME}\)=\('[ ${VARCHARS}]*'\)$/\1=\2/p" "${CONFIG}"
}

function loadconf() {
    local CONFIG="$1"
    eval $(readhash "${CONFIG}")
}

function loadSettings() {
    local CONFIG="$1"
    local file=$(basename "$CONFIG")
    local dir=$(dirname "$CONFIG")
    local module=$(basename "$dir")
    local default="$dir/default/$file"
    local vendor="$dir/vendor/$file"
    local defaultNew="${PERSISTENT_D}/${module}/default/$file"
    local vendorNew="${PERSISTENT_D}/${module}/vendor/$file"
    local defaultNew2="${PERSISTENT_D}/${module}/default/${file}.*"
    local stateDir="/var/lib/efw/${module}/${file}"
    local stateDir2="/var/lib/efw/${module}/${file}.*"
    for i in \
	$default \
	$defaultNew \
	$defaultNew2 \
	$vendor \
	$vendorNew \
	${CONFIG} \
	$stateDir \
	$stateDir2; do
	if [ -e "${i}" ]; then
	    loadconf "${i}"
	fi
    done
}

function log_done() {
    local MSG="$1"
    local tag="$2"
    if [ -z "$tag" ]; then
        tag="$logger_tag"
    fi
    if [ -n "$tag" ]; then
        tag="-t $tag"
    fi

    echo "$MSG"
    logger -p daemon.info "$tag" "$MSG"
}

function log_failed() {
    local MSG="$1"
    local tag="$2"
    if [ -z "$tag" ]; then
        tag="$logger_tag"
    fi
    if [ -n "$tag" ]; then
        tag="-t $tag"
    fi
    echo "ERROR: $MSG"
    logger -p daemon.err "$tag" "$MSG"
}

run_hook() {
    local script="$1"
    local exit_status

    if [ -f $script ]; then
        . $script
    fi

    if [ -n "$exit_status" ] && [ "$exit_status" -ne 0 ]; then
        log_failed "$script returned non-zero exit status $exit_status"
        save_exit_status=$exit_status
    fi

    return $exit_status
}

function run_hookdir() {
    local dir="$1"
    local exit_status

    if [ -d "$dir" ]; then
        for script in $(run-parts --list $dir); do
            run_hook $script || true
            exit_status=$?
        done
    fi

    return $exit_status
}

function lowercase() {
    local STR="$1"
    echo $STR | tr "[:upper:]" "[:lower:]"
}
function mutex_begin() {
    local id="$1"

    # timeout of 500 seconds
    lockfile -l 500 ${LOCKFILES}_${id}.lock
}
function mutex_end() {
    local id="$1"
    rm -f ${LOCKFILES}_${id}.lock 2>/dev/null
}

function function_exists() {
    local F="$1"
    typeset -F ${F} >/dev/null 2>/dev/null
    return $?
}


function wan_active_count() {
    ls -1 ${UPLINK_DIR}/*/active 2>/dev/null | wc -l
}

function bailout() {
    log_failed "$1"
    exit 1
}


function save_old_settings() {
    local F="$1"
    if [ -z "$F" ]; then
	return
    fi
    if [ ! -f "$F" ]; then
	return
    fi
    local base=$(echo $F | \
	sed "s,^\(${USER_D}\|${PERSISTENT_D}\|${VOLATILE_D}\|${SHELL_CONFIG}\|${STATE_D}\),,")
    local target="${F}.old"
    if [ "${base}" != "${target}" ]; then
	target="${STATE_D}/${base}.old"
    fi

    mkdir_p $(dirname $target)
    cp $F $target 2>/dev/null
}

function call() {
    local ARG1=$1
    shift 1
    local PARAMARGS=$*

    local CMD=$(echo $ARG1 | cut -d ' ' -f 1)
    local ARGS=$(echo $ARG1 | cut -d ' ' -f 2-)
    if [ "$CMD" == "$ARG1" ]; then
        ARGS=""
    fi

    if [ ! -x "$CMD" ]; then
	if [ ! -x "$(which $CMD)" ]; then
	    return
	fi
    fi
    $CMD $ARGS $PARAMARGS
}

function addOrReplace() {
    local KEY=$1
    local REPLACE=$2
    local FILE=$3

    if grep -qEe "^${KEY}=" $FILE; then
	sed -i -e "s/^${KEY}=.*/${KEY}=${REPLACE}/" $FILE
	return
    fi
    echo "${KEY}=${REPLACE}" >> $FILE
}


#
# ALlows to check if an ip rule already exists by
# filtering over ip rule list and printing out rules
# which match the output
#
function existsIpRule() {
    local addRule="$1"

    function createGrep() {
	local tokenize=$addRule
	while [ -n "$tokenize" ]; do
	    local key=$(echo $tokenize | cut -d ' ' -f 1)
	    local val=$(echo $tokenize | cut -d ' ' -f 2)
	    tokenize=$(echo $tokenize | cut -d ' ' -f 3-)
	    
	    if [ "$key" == "prio" ]; then
		echo "| grep \"^${val}:\""
		continue
	    fi
	    echo "| grep \"$key $val\""
	done
    }

    line=$(createGrep $addRule | tr "\n" " ")
    sh -c "ip rule list $line "
}

#
# adds ip rule uniquely in order to have no ip rules twice
#
function ipRuleAddUnique() {
    local rule="$*"
    existsIpRule "$rule" >/dev/null && return 0
    ip rule add $rule
}

#
# deletes all matches of an ip rule del line
#
function ipRuleDelAll() {
    local ok=0
    local err=0
    while [ $err -eq 0 ]; do
	ip rule del $* 2>/dev/null
	err=$?
	if [ $err -eq 0 ]; then
	    ((ok++))
	fi
    done
    if [ $ok -gt 0 ]; then
	return 0
    fi
    return $err
}


function installHAFirewallRules() {
    local action="$1"
    rm -f ${FIREWALL}/*/ha-*.conf &>/dev/null

    ls -1d ${FIREWALL}/*/notuse | \
	while read F; do
	    local base=$(dirname $F)
	    cp -fs ${F}/ha-${action}-*.conf $base/ &>/dev/null
    done
}

function mkdir_p() {
    local dir="$1"
    mkdir -p $dir
}

if [ "$0" == "efw_lib.sh" ]; then
    echo "TEST SECTION"
#    INITSCRIPTS=.
#    rc_start "updatered" "active"
#    loadconf "test"
#    echo "..${TEST}"
fi
