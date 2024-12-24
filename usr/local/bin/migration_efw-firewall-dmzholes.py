#!/usr/bin/env python
# -*- coding: utf-8 -*-
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

from endian.core.logger import debug, logger, logging
from endian.core.csvfile import CSVFile
import os
import re
import sys
from os import system as run
from optparse import OptionParser

logger.setLevel(logging.INFO)

DMZHOLES='/var/efw/dmzholes/config'
ZONEFW='/var/efw/zonefw/config'

class DMZholes:
    def __init__(self):
        self._meta = ['proto', 'src_ip', 'dst_ip', 'dst_port', 'enabled', 'src_zone', 'dst_zone', 'remark']
        self.enabled = 'on'
        self.src_ip = '0/0'
        self.dst_ip = '0/0'
        self.dst_port = ''
        self.src_zone = ''
        self.dst_zone = ''
        self.proto = ''
        self.remark = ''


class ZonefwEntry:
    def __init__(self):
        self._meta = ['enabled', 'proto', 'src_ip', 'dst_ip', 'dst_port', 'target', 'mac', 'remark', 'log', 'src_dev', 'dst_dev']
        self.enabled = 'on'
        self.src_ip = ''
        self.dst_ip = ''
        self.dst_port = ''
        self.target = 'ACCEPT'
        self.mac = ''
        self.remark = ''
        self.log = 'off'
        self.src_dev = ''
        self.dst_dev = ''
        self.proto = ''

def is_macaddress(addr):
    ippattern = re.compile("^(?:[\dA-F]{2}:){5}[\dA-F]{2}$")
    if (ippattern.match(addr)):
        return True
    return False




def opthandler():
    usage = "usage: %prog <options>"
    parser = OptionParser(usage)

    parser.add_option("-d", "--debug", dest="debug",
                      action="store_true",
                      help="be more verbose", default=False)
    (options, args) = parser.parse_args()
    return options

options = opthandler()
if options.debug:
    logger.setLevel(logging.DEBUG)
else:
    logger.setLevel(logging.INFO)


debug("Check for migration of dmzholes config file")
if not os.path.exists(DMZHOLES):
    sys.exit(0)

f = CSVFile(DMZHOLES, DMZholes(), tolerant=False)
config = f.load()

t = CSVFile(ZONEFW, ZonefwEntry(), tolerant=True)
writeconf = t.load()

i=0
for rule in config._data:
    i +=1
    debug("Process line %s"%i)
    add = ZonefwEntry()
    add.enabled = rule.enabled
    add.src_ip = rule.src_ip
    add.dst_ip = rule.dst_ip
    if rule.dst_port != '-':
        add.dst_port = rule.dst_port
    add.proto = rule.proto
    add.remark = rule.remark
    if is_macaddress(rule.src_ip):
        add.mac = rule.src_ip
        add.src_ip = ''
    writeconf._data.append(add)

debug("Add old standard configuration")
add = ZonefwEntry()
add.src_dev = 'GREEN'
add.dst_dev = 'GREEN&BLUE&ORANGE'
writeconf._data.append(add)

add2 = ZonefwEntry()
add2.src_dev = 'BLUE'
add2.dst_dev = 'BLUE'
writeconf._data.append(add2)

add3 = ZonefwEntry()
add3.src_dev = 'ORANGE'
add3.dst_dev = 'ORANGE'
writeconf._data.append(add3)

debug("Write down migration of dmzholes config file to zonefw")
t.store()
run("chown nobody:nogroup %s"%ZONEFW)
os.unlink(DMZHOLES)


