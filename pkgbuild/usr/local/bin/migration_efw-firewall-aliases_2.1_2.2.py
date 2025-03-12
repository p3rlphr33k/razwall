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

logger.setLevel(logging.INFO)


class Xtaccess:
    def __init__(self):
        self._meta = ['proto', 'src_ip', 'dst_port', 'enabled', 'dst_ip', 'dst_dev', 'log', 'logprefix', 'target', 'mac', 'remark']
        self.enabled = 'on'
        self.src_ip = '0/0'
        self.dst_ip = '0/0'
        self.dst_port = ''
        self.log = 'off'
        self.dst_dev = ''
        self.proto = ''
        self.logprefix = 'XTACCESS'
        self.target = 'ACCEPT'
        self.mac = ''
        self.remark = ''

class Portfw:
    def __init__(self):
        self._meta = ['key1', 'key2', 'proto', 'src_port', 'target_ip', 'target_port', 'enabled', 'src_ip', 'access_ip', 'remark', 'src_dev', 'log', 'nat']
        self.key1 = '0'
        self.key2 = '0'
        self.proto = ''
        self.src_port = ''
        self.target_ip = ''
        self.target_port = ''
        self.enabled = 'on'
        self.src_ip = '0/0'
        self.access_ip = '0/0'
        self.remark = ''
        self.log = 'off'
        self.src_dev = ''
        self.nat = ''

debug("Check for migration of xtaccess config file")
f = CSVFile('/var/efw/xtaccess/config', Xtaccess(), tolerant=True)
config = f.load()
i=0
dirty = False
for rule in config._data:
    i +=1
    debug("Process line %s"%i)
    if rule.dst_ip != '0.0.0.0' and rule.dst_dev == '':
        dirty=True
        rule.dst_dev = 'RED'
        debug("Migrate adding RED as destination device")
        rule.log = 'off'

if dirty:
    f.store()
    debug("Write down migration of xtaccess file")



debug("Check for migration of portfw config file")
f = CSVFile('/var/efw/portfw/config', Portfw(), tolerant=True)
config = f.load()
i=0
dirty = False
for rule in config._data:
    i +=1
    debug("Process line %s"%i)
    if rule.key2 != '0':
        continue
    if rule.src_ip != '0.0.0.0' and rule.src_dev == '':
        dirty=True
        rule.src_dev = 'UPLINK:main'
        debug("Migrate adding main uplink as source device")
        rule.log = 'off'

if dirty:
    f.store()
    debug("Write down migration of portfw file")
