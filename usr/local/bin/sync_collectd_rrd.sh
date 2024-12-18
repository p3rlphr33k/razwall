#!/bin/sh
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2012 Endian                                              |
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
# This script synchronize the /tmp/collectd/rrd/$UUID directory with
# the one in /var/lib/collectd/rrd/
# If the -i is given, source and target directories are switched.
#


UUID="`cat /etc/uuid`"

if [ -z "$UUID" ] ; then
	UUID="`hostname`"
fi

NO_ACT=0
INVERT=0

function sync_help
{
	echo "Synchronize the /tmp/collectd/rrd/ directory with"
	echo "the one in /var/lib/collectd/rrd/"
	echo "Options:"
	echo "	-i	source and target directories are switched."
	echo "	-n	do not act"
	echo "	-n	print this help and exit"
}


while getopts "inh" opt $@ ; do
	case $opt in
		i)
			INVERT=1
			;;
		n)
			NO_ACT=1
			;;
		h)
			sync_help
			exit 0
			;;
		\?)
			sync_help
			exit 1
			;;
	esac
done

VAR_PATH="/var/lib/collectd/rrd/$UUID/"
TMP_PATH="/tmp/collectd/rrd/$UUID/"

mkdir -p "$TMP_PATH"
mkdir -p "$VAR_PATH"

if [ ! -d "$VAR_PATH" ] ; then
	echo "Missing RRD directory: $VAR_PATH" >&2
	exit 10
fi

SRC_PATH="$TMP_PATH"
DST_PATH="$VAR_PATH"
if [ $INVERT -eq 1 ] ; then
	SRC_PATH="$VAR_PATH"
	DST_PATH="$TMP_PATH"
fi

RSYNC_OPTS="-car --del"

if [ $NO_ACT -eq 1 ] ; then
	echo "Would run: rsync $RSYNC_OPTS $SRC_PATH $DST_PATH"
	echo ""
	RSYNC_OPTS="-nvcar --del"
fi

rsync $RSYNC_OPTS "$SRC_PATH" "$DST_PATH"
RET=$?

if [ $INVERT -eq 0 ] ; then
	NOW=$(date "+%s")
	# check .rrd files timestamps
	find $VAR_PATH -name "*.rrd" -print | \
	    while read F; do
	    LAST=$(rrdtool last $F)
	    if [ "$LAST" -gt "$NOW" ]; then
		echo "rrd file $F contains timestamps in future. Remove the file!"
		rm -f $F
	    fi
	done

	# fix tail overflow counters
	ls -1 /var/lib/collectd/rrd/*/tail*/*.rrd | \
	    while read F; do
	    if rrdtool info $F | grep -q "ds\[value\].max.*NaN"; then
		echo "rrd file $F has no max limit causing wrong overflows. Remove the file!"
		rm -f $F
	    fi
	done
fi

exit $RET

