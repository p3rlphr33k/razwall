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
import sys

logger.setLevel(logging.INFO)

CONFIG='/var/efw/outgoing/config'

class Outgoing:
    def __init__(self):
        self._meta = ['enabled', 'proto', 'src_ip', 'dst_ip', 'dst_port', 'target', 'mac', 'remark', 'log', 'src_dev', 'dst_dev']
        self.enabled = 'on'
        self.src_ip = '0/0'
        self.dst_ip = '0/0'
        self.dst_port = ''
        self.target = 'ACCEPT'
        self.mac = ''
        self.remark = ''
        self.log = 'off'
        self.src_dev = ''
        self.dst_dev = ''
        self.proto = ''

debug("Check for migration of outgoing firewall config file")
if not os.path.exists(CONFIG):
    sys.exit(0)

t = CSVFile(CONFIG, Outgoing(), tolerant=True)
writeconf = t.load()

i=0
dirty=False
for rule in t._data:
    i +=1
    debug("Process line %s"%i)
    if rule.src_ip in ['GREEN', 'BLUE', 'ORANGE', 'RED', 'ALL']:
        rule.src_dev = rule.src_ip
        if rule.src_dev == 'ALL':
            rule.src_dev = '';
        rule.src_ip = ''
        dirty = True

if dirty:
    t.store()
    debug("Write down migration of dmzholes config file to zonefw")
