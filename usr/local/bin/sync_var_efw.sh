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
# This script synchronize the /var/efw/ directory with /usr/lib/efw_backup/
# If the -i is given, source and target directories are switched.
# With -d dir, you can override the target directory (useful when called by createvar.py)
#

NO_ACT=0
INVERT=0
FORCE_DEST=""

function sync_help
{
	echo "Synchronize the /var/efw/ directory with /usr/lib/efw_backup/"
	echo "Options:"
	echo "	-i	source and target directories are switched."
	echo "	-n	do not act"
	echo "	-d dir	override target dir"
	echo "	-h	print this help and exit"
}


while getopts "ind:h" opt $@ ; do
	case $opt in
		i)
			INVERT=1
			;;
		n)
			NO_ACT=1
			;;
		d)
			FORCE_DEST="$OPTARG";
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

VAR_EFW_PATH="/var/efw/"
USR_LIB_PATH="/usr/lib/efw_backup/"
SRC_PATH="$VAR_EFW_PATH"
DST_PATH="$USR_LIB_PATH"
if [ $INVERT -eq 1 ] ; then
	SRC_PATH="$USR_LIB_PATH"
	DST_PATH="$VAR_EFW_PATH"
fi

if [ ! -d "$SRC_PATH" ] ; then
	echo "Missing source directory: $SRC_PATH" >&2
	exit 10
fi

if [ -n "$FORCE_DEST" ] ; then
	DST_PATH="$FORCE_DEST"
fi

if [ ! -d "$DST_PATH" ] ; then
	mkdir -p "$DST_PATH"
fi


RSYNC_OPTS="-car --del"

if [ $NO_ACT -eq 1 ] ; then
	echo "Would run: rsync $RSYNC_OPTS $SRC_PATH $DST_PATH"
	echo ""
	RSYNC_OPTS="-nvcar --del"
fi

rsync $RSYNC_OPTS "$SRC_PATH" "$DST_PATH"
RET=$?

exit $RET

