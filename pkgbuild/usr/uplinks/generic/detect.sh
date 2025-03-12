#!/bin/sh
#
# Hardware detection helper functions
#

export HW_COUNTER=0

USB_DEVICES=/proc/bus/usb/devices

function detect_usb() {
    local vendor="$1"
    local prod="$2"
    
    if [ -e $USB_DEVICES ]; then
	local count=$(grep -c "Vendor=$1 ProdID=$2" $USB_DEVICES)
	HW_COUNTER=$[$HW_COUNTER+$count]
    else
	echo "ERROR: detect_usb cannot open $USB_DEVICES"
    fi
}

function detect_pci() {
    local vendor="$1"
    local prod="$2"

    local count=$(lspci -n -d $vendor:$prod | wc -l)
    HW_COUNTER=$[$HW_COUNTER+$count]
}

function detect_show() {
    echo $HW_COUNTER
}
