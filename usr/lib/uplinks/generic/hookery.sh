#!/bin/sh
#
# hook related functions
#

. ${UPLINK_SCRIPTS}/generic/data.sh

ULDAEMONPID="/var/run/uplinksdaemon.pid"

function uplink_hooks_up() {
    local uplink="$1"

    mutex_begin "uplink"
    run_hookdir "${USER_D}/uplinks/${uplink}/ifup.d"
    run_hookdir "/etc/network/ifup.d"
    mutex_end "uplink"
}

function uplink_hooks_down() {
    local uplink="$1"

    mutex_begin "uplink"
    run_hookdir "${USER_D}/uplinks/${uplink}/ifdown.d"
    run_hookdir "/etc/network/ifdown.d"
    mutex_end "uplink"
}

function failure() {
    local STR="$1"
    if [ -z "$STR" ]; then
	STR="Could not bring up link '${uplink}'"
    fi
    set_failure "$uplink"
    bailout "$STR"
}

function save_pid() {
    local uplink="$1"
    mkdir_p "${UPLINK_RUN}/$uplink"
    chown nobody:nogroup "${UPLINK_RUN}/$uplink"
    echo $$ > "${UPLINK_RUN}/$uplink/pid.pid"
}

function write_timestamp() {
    local file="$1"

    local ts=$(date "+%s")
    mkdir_p $(dirname $file)
    chown nobody:nogroup $(dirname $file)
    echo $ts > $file
}

function get_grandfather_pid() {
    local pid="$1"
    cut -f 4 -d ' ' /proc/${pid}/stat
}

function notify_callppp() {
    local uplink="$1"
    local value="$2"
    [ ! -e "${UPLINK_RUN}/$uplink/$uplink.fifo" ] && return

    # check if the corresponding pppcall is running
    local pppcallpidfile="/var/run/ppp/${uplink}.pid"
    local pppdpidfile="/var/run/ppp-${uplink}.pid"
    [ ! -e "$pppcallpidfile" ] && return
    [ ! -e "/proc/$(cat $pppcallpidfile)/" ] && return

    # check if pppd is our parent process
    [ ! -e "$pppdpidfile" ] && return
    local pppdpid=$(cat $pppdpidfile | head -n 1)
    # only ip-up/ip-down should write to the fifo
    #                                       # PPID is run-parts
    PPPID=$(get_grandfather_pid "$PPID")    # this is ip-up
    PPPPID=$(get_grandfather_pid "$PPPID")  # this is pppd
    [ "$PPPPID" != "$pppdpid" ] && [ "$PPID" != "$pppdpid" ] && return

    log_done "Notify pppcall about status change of uplink '$uplink'. Send $value"
    echo "$value" >> "${UPLINK_RUN}/$uplink/$uplink.fifo"
}

function notify_uplinksdaemon() {
    local uplink="$1"
    local value="$2"
    [ ! -e "$ULDAEMONPID" ] && return
    log_done "Notify uplinks daemon about status change of uplink '$uplink'. Status id $value"
    /etc/init.d/uplinksdaemon notify 2>/dev/null
}

function notify() {
    local uplink="$1"
    local value="$2"
    local status=""

    notify_callppp $*
    mkdir_p "${UPLINK_RUN}/$uplink"
    chown nobody:nogroup "${UPLINK_RUN}/$uplink"
    touch "${UPLINK_RUN}/$uplink/notified"
    notify_uplinksdaemon $*
    if [ "$value" == "OK" ]; then
	status="ONLINE"
    fi
    if [ "$value" == "FAILED" ]; then
	status="OFFLINE"
    fi
    log_done "Uplink '$uplink' status: '$status'"
}

# sets the uplink active
function set_active() {
    local uplink="$1"
    local datafile="$2"

    write_timestamp "${UPLINK_RUN}/$uplink/active"
    rm -f "${UPLINK_RUN}/$uplink/connecting"
    rm -f "${UPLINK_RUN}/$uplink/disconnecting"
    rm -f "${UPLINK_RUN}/$uplink/pid.pid"
    rm -f "${UPLINK_RUN}/$uplink/failure"
    save_uplink_settings "${uplink}" "$datafile"
    notify "$uplink" "OK"
}

function set_connecting() {
    local uplink="$1"

    save_pid "${uplink}"
    write_timestamp "${UPLINK_RUN}/$uplink/connecting"
    rm -f "${UPLINK_RUN}/$uplink/active"
    rm -f "${UPLINK_RUN}/$uplink/disconnecting"
    rm -f "${UPLINK_RUN}/$uplink/failure"
}

function set_disconnecting() {
    local uplink="$1"

    write_timestamp "${UPLINK_RUN}/$uplink/disconnecting"
    rm -f "${UPLINK_RUN}/$uplink/connecting"
    rm -f "${UPLINK_RUN}/$uplink/active"
    touch "${UPLINK_RUN}/$uplink/pid.pid"
    rm -f "${UPLINK_RUN}/$uplink/failure"
}

function set_failure() {
    local uplink="$1"

    rm -f "${UPLINK_RUN}/$uplink/connecting"
    rm -f "${UPLINK_RUN}/$uplink/disconnecting"
    rm -f "${UPLINK_RUN}/$uplink/active"
    rm -f "${UPLINK_RUN}/$uplink/pid.pid"
    write_timestamp "${UPLINK_RUN}/$uplink/failure"
    notify "$uplink" "FAILED"
}

function set_inactive() {
    local uplink="$1"

    rm -f "${UPLINK_RUN}/$uplink/active"
    rm -f "${UPLINK_RUN}/$uplink/connecting"
    rm -f "${UPLINK_RUN}/$uplink/disconnecting"
    rm -f "${UPLINK_RUN}/$uplink/pid.pid"
    rm -f "${UPLINK_RUN}/$uplink/failure"
    rm -f "${UPLINK_RUN}/$uplink/data*"
    notify "$uplink" "FAILED"
}

function is_locked() {
    local uplink="$1"

    test -e "${UPLINK_RUN}/$uplink/pid.pid" && return 0
    return 1
}

function is_connecting() {
    local uplink="$1"

    test -e "${UPLINK_RUN}/$uplink/connecting" && return 0
    return 1
}

function is_active() {
    local uplink="$1"

    test -e "${UPLINK_RUN}/$uplink/active" && return 0
    return 1
}

