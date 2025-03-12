#!/bin/sh

FLAGFILE="/var/tmp/oldkernel"

RUNNING=$(uname -r)
REBOOT=1

if [ -e /boot/vmlinuz-${RUNNING} ]; then
    REBOOT=0
fi
if [ -e /boot/zImage-${RUNNING} ]; then
    REBOOT=0
fi
if [ -e /boot/bzImage-${RUNNING} ]; then
    REBOOT=0
fi

if [ $REBOOT -eq 1 ]; then
    # install notification message
    touch $FLAGFILE
    echo "Old kernel running. Reboot needed"
else
    if [ -e $FLAGFILE ]; then
        rm $FLAGFILE
    fi
fi
exit 0
