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

BACKUPDIR=/var/backups/
BACKUPCONF=/usr/lib/efw/backup/
BACKUPUSERCONF=/var/efw/backup/
FACTORYTARGET=/var/efw/factory/factory.tar.gz
ROOTAUTH=/etc/shadowroot

EXCLUDE_SYSTEM="${BACKUPCONF}/exclude.*system ${BACKUPUSERCONF}/exclude.*system"
INCLUDE_SETTINGS="${BACKUPCONF}/include.*system ${BACKUPUSERCONF}/include.*system"
INCLUDE_LOGS="${BACKUPCONF}/include.*logs ${BACKUPUSERCONF}/include.*logs"
INCLUDE_HWDATA="${BACKUPCONF}/include.*hwdata ${BACKUPUSERCONF}/include.*hwdata"
EXCLUDE_LOGARCHIVES="${BACKUPCONF}/include.*logarchives ${BACKUPUSERCONF}/include.*logarchives"
EXCLUDE_DUMPS="${BACKUPCONF}/include.*dumps ${BACKUPUSERCONF}/include.*dumps"
INSTALLERMETA=/root/installer.meta

GPGKEY=''

LOGS=0
LOGARCHIVES=0
HWDATA=0
DBDUMPS=0
SETTINGS=0
FACTORY=0
CRON=0
MESSAGE=""
TAG="backup-create"

CHILD=0

trap "quit" INT QUIT TERM

function usage() {
    cat <<EOF
Usage: $0 [--settings] [--logs] [--logarchives] [--hwdata] [--dbdumps] [--dbdumps] [--factory] [--gpgkey=GPGKEY] [--nosleep]
    --settings: includes all settings files
                uses '${BACKUPDIR}include.system' listing, but excludes
                database dumps listed in '${BACKUPDIR}include.dumps'
    --logs:     includes all log files within backups.
                uses '${BACKUPDIR}include.logs' listing, but excludes log 
                archives listed in '${BACKUPDIR}include.logarchives'
    --logarchives: includes also (does not exclude) log archives, listed
                   in '${BACKUPDIR}include.logarchives'
    --hwdata:   includes hardware data files.
                uses '${BACKUPDIR}include.hwdata' listing
    --dbdumps:  includes (does not exclude) database dumps listed in
                '${BACKUPDIR}include.dumps'
    --cron:     signalizes that the backup has been created by a cronsscript
    --factory:  creates factory defaults backup which includes only settings
    --message:  puts a message within meta data file
    --gpgkey:   encrypt the backup with the supplied gpg key
    --nosleep:  disable backup creation sleep
EOF

}

function quit() {
    local code="$1"
    end_notifications
    exit $code
}

function log() {
    local MSG="$1"
    if [ -z "$MSG" ]; then
        return
    fi
    echo "$MSG" >&2
    error $1
    logger -p daemon.warning -t "$TAG" "$MSG"
}

function options() {
    OPT=$(getopt -o lahdscfm:g: --long logs,logarchives,hwdata,dbdumps,settings,cron,factory,message:,gpgkey:,nosleep -n "$TAG" -- "$@")
    if [ $? -ne 0 ]; then
        echo "Terminating..." >&2
        quit 1
    fi

    NOSLEEP=0
    eval set -- "$OPT"
    while true; do
        case "$1" in
            -l|--logs) LOGS=1; shift;;
            -a|--logarchives) LOGARCHIVES=1; shift;;
            -h|--hwdata) HWDATA=1; shift;;
            -d|--dbdumps) DBDUMPS=1; shift;;
            -s|--settings) SETTINGS=1; shift;;
            -c|--cron) CRON=1; shift;;
            -f|--factory) FACTORY=1; SETTINGS=1; DBDUMPS=1; shift;;
            -m|--message) MESSAGE="$2"; shift 2;;
            -g|--gpgkey) GPGKEY="$2"; shift 2;;
            -n|--nosleep) NOSLEEP=1; shift;;
            --) shift; break;;
            *) echo "Invalid Option! '$1'" >&2; quit 1;;
        esac
    done

    if [ $LOGS -eq 0 -a $SETTINGS -eq 0 -a $DBDUMPS -eq 0 -a $LOGARCHIVES -eq 0 -a $HWDATA -eq 0 -a $FACTORY -eq 0 ]; then
        usage
        quit 1
    fi
}

function targetname() {
    if [ $FACTORY -eq 1 ]; then
        TARGET=${FACTORYTARGET}
        return
    fi
    DNS=$(hostname)
    NOW=$(date -u "+%Y%m%d%H%M%S%Z")

    PREFIX="${BACKUPDIR}backup-$NOW-$DNS"
    if [ $SETTINGS -eq 1 ]; then
        PREFIX="${PREFIX}-settings"
    fi
    if [ $DBDUMPS -eq 1 ]; then
        PREFIX="${PREFIX}-db"
    fi
    if [ $LOGS -eq 1 ]; then
        PREFIX="${PREFIX}-logs"
    fi
    if [ $LOGARCHIVES -eq 1 ]; then
        PREFIX="${PREFIX}-logarchive"
    fi
    if [ $HWDATA -eq 1 ]; then
        PREFIX="${PREFIX}-hwdata"
    fi
    if [ $CRON -eq 1 ]; then
        PREFIX="${PREFIX}-cron"
    fi
    TARGET="$PREFIX.tar.gz"
}

function presettings() {
    grep -Ee "^root" /etc/shadow > ${ROOTAUTH}
    test -x /usr/local/bin/rpmlist.sh && /usr/local/bin/rpmlist.sh
    cp ${INSTALLERMETA} ${INSTALLERMETA}.backup 2>/dev/null
    chmod 000 ${ROOTAUTH}
}

function predumps() {
    test -x /etc/cron.daily/psql_dump && /etc/cron.daily/psql_dump
    test -x /etc/cron.daily/mongodb_dump && /etc/cron.daily/mongodb_dump
}

function backup() {

    # create include/exclude listings
    INCLUDE=$(mktemp "/var/tmp/backup-inclusion.XXXXXX")
    EXCLUDE=$(mktemp "/var/tmp/backup-exclusion.XXXXXX")
    cat ${EXCLUDE_SYSTEM} 2>/dev/null >> $EXCLUDE

    if [ $SETTINGS -eq 1 ]; then
        cat ${INCLUDE_SETTINGS} 2>/dev/null >> $INCLUDE
    fi
    if [ $DBDUMPS -eq 1 ]; then
        cat ${EXCLUDE_DUMPS} 2>/dev/null >> $INCLUDE
    else
        cat ${EXCLUDE_DUMPS} 2>/dev/null >> $EXCLUDE
    fi

    if [ $LOGS -eq 1 ]; then
        cat ${INCLUDE_LOGS} 2>/dev/null >> $INCLUDE
        if [ ! $LOGARCHIVES -eq 1 ]; then
            cat ${EXCLUDE_LOGARCHIVES} 2>/dev/null >> $EXCLUDE
        fi
    elif [ $LOGARCHIVES -eq 1 ]; then
        cat ${EXCLUDE_LOGARCHIVES} 2>/dev/null >> $INCLUDE
    fi
    if [ $HWDATA -eq 1 ]; then
        cat ${INCLUDE_HWDATA} 2>/dev/null >> $INCLUDE
    fi
    if [ ! -s $INCLUDE ]; then
        log "Nothing to backup!"
        quit 0
    fi

    # create tar
    TMPTAR=$(mktemp "/var/tmp/backup.tar.XXXXXX")
    info "Creating backup..."
    if [ $NOSLEEP -eq 0 ]; then
        sleep 20
    fi
    tar --ignore-failed-read -T $INCLUDE -X $EXCLUDE -C / -cf $TMPTAR &>/dev/null
    if [ $? -gt 1 ]; then
        rm -f $TMPTAR $INCLUDE &>/dev/null
        log "Could not create backup '$TMPTAR'!"
        quit 1
    fi
    rm -f $INCLUDE &>/dev/null
    rm -f $EXCLUDE &>/dev/null

    # zip the tar
    if ! gzip $TMPTAR 2>/dev/null; then
        log "Could not compress backup '$TMPTAR.gz'"
        rm -f $TMPTAR* &>/dev/null
        quit 1
    fi
    if ! gzip -t $TMPTAR.gz 2>/dev/null; then
        log "Compressed backup '$TMPTAR.gz' invalid"
        rm -f $TMPTAR* &>/dev/null
        quit 1
    fi

    # bring the tar.gz in place
    if ! mv -f $TMPTAR.gz $TARGET; then
        log "Could not bring backup '$TARGET' in place!"
        rm -f $TARGET &>/dev/null
        quit 1
    fi

    if [ -n "${GPGKEY}" ]; then
        info "Encrypting backup..."
        if ! gpg --homedir /root/.gnupg --always-trust --batch --encrypt --recipient ${GPGKEY} -o - $TARGET >$TARGET.gpg; then
            log "Could not encrypt backup '$TARGET' with public key '${GPGKEY}'!"
        fi
    fi

    echo $MESSAGE > $TARGET.meta
    chown nobody.nogroup ${TARGET}*
}

function enable_notifications() {
    if [ -f "/var/lock/services/backup.status" ]; then
        # if this script has been called by another backup-script
        # such as efw-backupusb, don't destroy the status file when
        # this process exits
        CHILD=1
    else
        echo -n "" > /var/lock/services/backup.status
    fi
    if [ -f "/var/lock/services/backup.history.status" -a $CHILD -eq 0 ]; then
        rm /var/lock/services/backup.history.status
    fi
    if [ -f "/var/lock/services/backup.error" -a $CHILD -eq 0 ]; then
        rm /var/lock/services/backup.error
    fi
}
function info() {
    logger -p daemon.info -t "$TAG" "$1"
    echo "{\"msg\": \"$1\", \"type\": \"info\", \"time\": `date +%s`}" > /var/lock/services/backup.status
    if [ ! -f "/var/lock/services/backup.history.status" ]; then
        echo "{\"msg\": \"$1\", \"type\": \"info\", \"time\": `date +%s`}" > /var/lock/services/backup.history.status
    fi
}
function error() {
    echo "{\"msg\": \"$1\", \"type\": \"error\", \"time\": `date +%s`}" > /var/lock/services/backup.error
}
function end_notifications() {
    if [ $CHILD -eq 0 ]; then
        rm /var/lock/services/backup.status &>/dev/null
    fi
}

enable_notifications

TARGET=""
options "$@"
targetname

if [ $SETTINGS -eq 1 ]; then
    info 'Prepare data for backup...'
    presettings
fi

if [ $DBDUMPS -eq 1 ]; then
    info 'Prepare dumps for backup...'
    predumps
fi

if [ -e $TARGET ]; then
   log "Target archive '$TARGET' does already exist!";
   quit 1
fi
backup
info "Archive '$TARGET' successfully created!" 

end_notifications

echo $TARGET

# Force sync
jobcontrol call base.noop &>/dev/null

quit 0
