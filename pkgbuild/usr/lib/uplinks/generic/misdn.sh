#!/bin/sh
#
# misdn related funtions
#

function misdn_init() {
    modprobe mISDN_core || failure "Could not load misdn modules"
    modprobe mISDN_l1 || failure "Could not load misdn modules"
    modprobe mISDN_l2 || failure "Could not load misdn modules"
    modprobe l3udss1 || failure "Could not load misdn modules"
    modprobe mISDN_capi || failure "Could not load misdn modules"
    modprobe mISDN_isac || failure "Could not load misdn modules"
}
