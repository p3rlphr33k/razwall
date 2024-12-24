#!/bin/sh

POWER="/sys/class/leds/led:orange:power"
STORAGE="/sys/class/leds/led:orange:storage"

echo "timer" > $POWER/trigger
echo "20" > $POWER/delay_off
echo "20" > $POWER/delay_on
echo "timer" > $STORAGE/trigger
echo "20" > $STORAGE/delay_off
echo "20" > $STORAGE/delay_on

/sbin/reboot -n -f
