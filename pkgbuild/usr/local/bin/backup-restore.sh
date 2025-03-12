#!/bin/sh

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

PATH=/bin:/sbin:/usr/bin:/usr/sbin

BACKUPSCRIPT=/usr/local/bin/backup-create.sh
EXCLUDE_SYSTEM="/usr/lib/efw/backup/exclude.*system /var/efw/backup/exclude.*system"
FACTORYTARGET=/var/efw/factory/factory.tar.gz
INSTALLERMETA=/root/installer.meta

FACTORY=0
REBOOT=0
DELETESYSID=0
HAVE_LOGS=0
HAVE_SETTINGS=0
HAVE_POSTGRESQLDB=0
HAVE_MONGODB=0
FILE=""
BASENAME=""
TAG="backup-restore"
NOW=$(date "+%Y%m%d%H%M%S")

function usage() {
    cat <<EOF
Usage: $0 [--factory] [--reboot] [--delete-sysid]
    --factory:  restores to factory default
    --reboot:   reboots after restore
    --delete-sysid: deletes EN registration
EOF
}

function log() {
    local MSG="$1"
    if [ -z "$MSG" ]; then
        return
    fi
    echo "$MSG" >&2
    logger -p daemon.info -t "$TAG" "$MSG"
}

function options() {
    OPT=$(getopt -o fr --long factory,reboot,delete-sysid -n '$TAG' -- "$@")
    if [ $? -ne 0 ]; then
        echo "Terminating..." >&2
        exit 1
    fi

    eval set -- "$OPT"
    while true; do
        case "$1" in
            -f|--factory) FACTORY=1; shift;;
            -r|--reboot) REBOOT=1; shift;;
            -d|--delete-sysid) DELETESYSID=1; shift;;
            --) shift; break;;
            *) echo "Invalid Option! '$1'" >&2; exit 1;;
        esac
    done
    if [ $FACTORY -eq 1 ]; then
        FILE=$FACTORYTARGET
        return
    fi
    FILE="$1"
    if [ -z "$FILE" ]; then
        usage
        exit 1
    fi
}

function backup_remove() {
    local remove="$1"
    BACKUPFILE=$(sh $BACKUPSCRIPT --settings --message="Backup before restore of ${BASENAME}")
    if [ $? -ne 0 ]; then
        exit 1;
    fi
    if [ ! -e ${BACKUPFILE} ]; then
        log "Backup file '${BACKUPFILE}' not found!"
        exit 1;
    fi
    if [ "$remove" == "remove" ]; then
        tar -tzf ${BACKUPFILE} | grep -v "var/log" | xargs -i rm -f /{} &>/dev/null
    fi
}

function test_restore() {
    TMPDIR=$(mktemp -d "/var/tmp/restore_XXXXXX")
    if [ $? -ne 0 ]; then
         rmdir $TMPDIR
         log "Could not create temporary directory '$TMPDIR'"
         exit 1
    fi

    tar -C $TMPDIR -xzf $FILE &>/dev/null
    if [ $? -ne 0 ]; then
        rm -Rf ${TMPDIR} &>/dev/null
        log "Invalid archive file '$FILE'!"
        exit 1
    fi

    # check what the archive contains
    test -d ${TMPDIR}/var/efw/dhcp && HAVE_SETTINGS=1
    test -d ${TMPDIR}/var/log && HAVE_LOGS=1
    # postgres backup are now in /var/pgsql_backup but we keep testing also old path
    test -f ${TMPDIR}/var/efw/pgsql/psql-latest.dump.bz2 && HAVE_POSTGRESQLDB=1
    test -f ${TMPDIR}/var/pgsql_backup/psql-latest.dump.bz2 && HAVE_POSTGRESQLDB=1
    test -f ${TMPDIR}/var/efw/mongodb/mongodb-latest.dump.tar.xz && HAVE_MONGODB=1

    rm -Rf ${TMPDIR} &>/dev/null
}

function restore() {
    EXCLUDE=$(mktemp "/var/tmp/backup-inclusion.XXXXXX")
    cat ${EXCLUDE_SYSTEM} 2>/dev/null >> $EXCLUDE
    tar -C / -X ${EXCLUDE} -xzf $FILE &>/dev/null
}

function post_restore() {
    # fix timestamp problem
    if [ -f "/var/efw/backup/rpms" ];then
       touch /var/efw/backup/rpms
    fi

    # postgres backup are now in /var/pgsql_backup
    if [ -f "/var/efw/pgsql/psql-latest.dump.bz2" ] ; then
        mkdir -p /var/pgsql_backup
        mv /var/efw/pgsql/psql-latest.dump.bz2 /var/pgsql_backup/psql-latest.dump.bz2
    fi

    if [ -f "/var/pgsql_backup/psql-latest.dump.bz2" -a $HAVE_POSTGRESQLDB -eq 1 ]; then
        /etc/init.d/postgresql stop &>/dev/null
        sleep 3
        rm -Rf /var/lib/postgresql/data &>/dev/null
        /etc/init.d/postgresql start &>/dev/null
    fi

    if [ -f "/var/efw/mongodb/mongodb-latest.dump.tar.xz" -a $HAVE_MONGODB -eq 1 ]; then
        # restore MongoDB dump
        DIR=/var/tmp/mongodb_dump$$
        /etc/init.d/mongod start &>/dev/null
        mkdir -p $DIR
        cd $DIR
        tar xf /var/efw/mongodb/mongodb-latest.dump.tar.xz
        cd -
        /usr/bin/mongorestore --drop $DIR &>/dev/null
        rm -rf $DIR
    fi

    if [ -s /etc/shadowroot ]; then
        grep -Eve "^root" /etc/shadow >> /etc/shadowroot
        cat /etc/shadowroot > /etc/shadow
    fi

    MESSAGE=""
    if [ -s $FILE.meta ]; then
        META=$(cat $FILE.meta)
        MESSAGE=" ($META)"
    fi
    cat >> $INSTALLERMETA << EOF
================ RESTORE ================
Restored '${BASENAME}'${MESSAGE} on '${NOW}'
================ TRACEBACK ${NOW} ================
EOF
    if [ -s $INSTALLERMETA.backup ]; then
        cat -n $INSTALLERMETA.backup >> $INSTALLERMETA
    else
        echo "No installer.meta found in archive" >> $INSTALLERMETA
    fi    
    echo "================ TRACEBACK ${NOW} ================" >> $INSTALLERMETA

    # fix permissions in /var/efw
    /usr/local/bin/efw-fixperms &> /dev/null
}

options "$@"
# That's a temporary fix: at some point a "stopallservices"
# event will be introduced.
if [ $REBOOT -eq 1 ]; then
	/etc/init.d/monit stop
fi

if [ ! -s ${FILE} ]; then
    log "Backup file '${FILE}' not found or empty!"
    exit 1
fi
BASENAME=$(basename ${FILE} 2>/dev/null)

test_restore
sleep 1
if [ $HAVE_SETTINGS -eq 1 ]; then
    backup_remove "remove"
else
    backup_remove
fi

restore
if [ $HAVE_SETTINGS -eq 1 -o $HAVE_POSTGRESQLDB -eq 1 -o $HAVE_MONGODB -eq 1 ]; then
    post_restore
fi
/usr/local/bin/efw-fixowners $FILE


if [ $DELETESYSID -eq 1 ]; then
    log "Successfully removed EN Registration"
    /usr/local/bin/restartenclient --delete-sysid
fi

if which emicommand &>/dev/null; then
    log "Start migration of configuration files"
    emicommand commands.migration.run
fi

log "Successfully restored '${BASENAME}'!"

if [ $REBOOT -eq 1 ]; then
    log "Successfully restored '${BASENAME}'! Rebooting..."
    reboot -i -d -f
    exit 0
fi

exit 0
