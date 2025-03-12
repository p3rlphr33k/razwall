#!/bin/sh
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2004-2016 S.p.A. <info@endian.com>                         |
# |         Endian S.p.A.                                                    |
# |         via Pillhof 47                                                   |
# |         39057 Appiano (BZ)                                               |
# |         Italy                                                            |
# |                                                                          |
# | This program is free software; you can redistribute it and/or modify     |
# | it under the terms of the GNU General Public License as published by     |
# | the Free Software Foundation; either version 2 of the License, or        |
# | (at your option) any later version.                                      |
# |                                                                          |
# | This program is distributed in the hope that it will be useful,          |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
# | GNU General Public License for more details.                             |
# |                                                                          |
# | You should have received a copy of the GNU General Public License along  |
# | with this program; if not, write to the Free Software Foundation, Inc.,  |
# | 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.              |
# +--------------------------------------------------------------------------+

PATH=/bin:/sbin:/usr/bin:/usr/sbin

HOTSPOT_RESET="/usr/local/bin/hotspot-reset.sh"
FACTORY=/var/efw/factory/factory.tar.gz

function reset_hotspot() {
    if [ -x $HOTSPOT_RESET ]; then
        sh $HOTSPOT_RESET
    fi
}

function reset_logs() {
    find /var/log/ -type f -exec rm -f {} \;
    touch /var/log/lastlog
    touch /var/log/wtmp
}

function reset_settings() {
    if [ ! -e $FACTORY ]; then
        return
    fi
    /usr/local/bin/backup-restore.sh --factory >/dev/null
    if [ -d /usr/lib/efw_backup ] ; then
	    rm -rf /usr/lib/efw_backup &>/dev/null
    fi
    grep -q "^KEEP_FACTORY_DEFAULT=on$" /var/efw/ethernet/settings &>/dev/null
    if [ $? -ne 0 ]; then
        rm -f /var/efw/ethernet/settings &>/dev/null
    fi
}

function reset_services {
    rm -Rf /var/spool/p3scan/notify/* &>/dev/null
    rm -Rf /var/spool/p3scan/children/* &>/dev/null
    rm -Rf /var/spool/havp/* &>/dev/null
    rm -Rf /var/spool/dansguardian/* &>/dev/null
    find /var/spool/postfix/{maildrop,defer{,red},active,bounce,corrupt,flush,hold,incoming,saved,trace} -type f -exec rm -f {} \;
    rm -Rf /var/spool/postfix/postgrey/* &>/dev/null
    rm -Rf /var/amavis/{db,mime,tmp,var,virusmails}/* &>/dev/null
    rm -Rf /var/cache/logwatch/* &>/dev/null
    rm -Rf /var/cache/menu/* &>/dev/null
    rm -Rf /var/lib/logrotate* &>/dev/null
    rm -Rf /var/lib/dhcp/*.{leases,info} &>/dev/null
    rm -Rf /var/lib/ntp/drift &>/dev/null
    rm -Rf /var/lib/spamassassin/* &>/dev/null
    rm -Rf /var/lib/pyzor/*.db &>/dev/null
    rm -Rf /var/lib/php/session/* &>/dev/null
    rm -Rf /var/lib/openvpn/*.leases &>/dev/null
    rm -Rf /var/lib/openvpn/clients/* &>/dev/null
    rm -Rf /var/virusmails/* &>/dev/null
    rm -Rf /var/lib/mongodb/* &>/dev/null
    rm -Rf /var/run/mongodb/* &>/dev/null
    rm -Rf /{,var/}tmp/* &>/dev/null
}

function reset_backups() {
    rm -Rf /var/efw/backup/sets/* &>/dev/null
    rm -f /home/httpd/html/backup/* &>/dev/null
    rm -f /var/backups/* &>/dev/null
    rm -f /var/lib/postgresql/backups/*.bz2 &>/dev/null
    rm -f /var/efw/mongodb/mongodb-latest.dump.tar.xz &>/dev/null
}

function reset_channels() {
    smart channel --remove-all -y
    rm -f /var/lib/smart/config.old
    rm -Rf /var/cache/en/* &>/dev/null
    rm -Rf /var/cache/en-* &>/dev/null
    rm -f /etc/endian/network/en-client.conf &>/dev/null
}

reset_logs
/etc/init.d/postgresql condstop &>/dev/null
/etc/init.d/mongod condstop &>/dev/null
reset_backups
reset_settings
reset_hotspot
reset_services
reset_channels
reboot

# Infinite sleep waiting for reboot...
while true; do sleep 10000; done
