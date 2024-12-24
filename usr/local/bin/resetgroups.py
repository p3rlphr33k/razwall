#!/usr/bin/python
#

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
# Author: raphael.lechner@endian.it
# Copyright: Endian
# License: GPL
# Date: 10.12.05
#

from os import system as run
from endian.job.engine_control import send_cmd_to_engine

PROXY_PATH       = "/var/efw/proxy/"
PROXY_SETTINGS   = PROXY_PATH + "/settings"


def getconfig(filename):
    """
    Reads a configuration file and returns a hash
    """
    config = {}
    try:
        for line in open(filename).xreadlines():
            line = line.strip()
            if line and line[0] != '#':
                line = line.split("=", 1)
                config[line[0]] = line[1]
    except:
        print "# Error reading config %s" % filename
        return 0
    return config


def writeconfig(config, filename):
    """
    Reset the enabled groups.
    groups_always_enabled -> groups_enabled
    """

    conf = open(filename, 'w')

    for key, value in config.items():
        if not key == "GROUPS_ENABLED":
            conf.write(key+"="+value+"\n")
    else:
        if 'GROUPS_ENABLED' in config:
            conf.write("GROUPS_ENABLED="+config['GROUPS_ENABLED']+"\n")
        else:
            conf.write("GROUPS_ENABLED=\n")

    conf.close()
    run("chown nobody.nogroup "+filename)


if __name__ == "__main__":
    config_values = {}
    config_values.update(getconfig(PROXY_SETTINGS))

    writeconfig(config_values, PROXY_SETTINGS)

    # restart proxy
    send_cmd_to_engine("restart squid")
