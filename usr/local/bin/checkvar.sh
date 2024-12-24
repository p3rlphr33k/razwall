#!/bin/sh

SDLAYOUT="/etc/formatsd-*.conf"

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

DEVNAME=${DEVNAME:-$1}

function is_prepared() {
    local rawdev=$(basename ${DEVNAME})
    local first=$(ls -d1 /sys/block/${rawdev}/${rawdev}* 2>/dev/null | head -1)

    [ -z "$first" ] && return 1;

    local dev="/dev/$(basename $first)"
    local label=$(vol_id --label $dev)

    [ -z "$label" ] && return 1;

    if grep -q "label=${label}$" ${SDLAYOUT}; then
	return 0;
    fi

    echo "Found unknown label ${label}. SD card will be overwritten"

    return 1;
}

if ! ls -1 ${SDLAYOUT} &>/dev/null; then
    echo "No SD layout file. Do not prepare SD card"
    exit 0
fi

if is_prepared; then
    echo "Device $DEVNAME is already prepared"
    exit 0
fi

echo "Prepare /var on device $DEVNAME"
logger -p daemon.info "checkvar" "Prepare /var on device $DEVNAME"
/usr/local/bin/createvar.py ${DEVNAME}
