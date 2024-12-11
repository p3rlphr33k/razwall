#!/bin/sh
# Set the system clock from hardware clock
# If the timestamp is more recent than the current time,
# use the timestamp instead.
hwclock --utc --hctosys
if test -e /etc/timestamp
then
        SYSTEMDATE=`date -u +%4Y%2m%2d%2H%2M`
        read TIMESTAMP < /etc/timestamp
        if [ ${TIMESTAMP} -gt $SYSTEMDATE ]; then
                date -u ${TIMESTAMP#????}${TIMESTAMP%????????}
                hwclock --utc --systohc
        fi
fi

