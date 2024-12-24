#!/usr/bin/python
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2008 Endian                                              |
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

from os import path, makedirs
import sys
import os
from glob import glob
import shutil
from endian.core.settingsfile import SettingsFile

# Loading the snort settings file and checking for the
# obsoleted key CUSTOM_RULES.
#
# If the CUSTOM_RULES is found, every rule file, located in 
# /etc/snort/rules/ is assumed to be a custom rule file and relocated
# into /etc/snort/custom. In addition the auto folder is created, where
# automatically fetched snort rules will be placed.
# 
# At the end, the CUSTOM_RULES key is removed from the settingsfile
# and replaced with the ENABLED_RULES key, which holds the name
# of all rule targets which are currently enabled (at the moment only auto and custom)

CONFIG = "/var/efw/snort/settings"
ETC = "/etc/snort"
RULES = "%s/rules" % (ETC)
CUSTOM_RULES = "%s/custom" % (RULES)
AUTO_RULES = "%s/auto" % (RULES)

def to_bool(val):
    if val == '1' or val == 'on':
        return True
    if val == '0' or val == 'off':
        return False
    return False

if not path.exists(CONFIG):
    sys.exit(0)

settings = SettingsFile(CONFIG)
# If CUSTOM_RULES is not found, it's a new installation or a really old one.
# In both cases, simply exit
if settings.get('custom_rules', None) == None:
    sys.exit(0)

# The custom and auto folders are created, if they don't exist already.
if not os.path.exists(CUSTOM_RULES):
    makedirs(CUSTOM_RULES)
if not os.path.exists(AUTO_RULES):
    makedirs(AUTO_RULES)

# Depending on the value of settings.get(CUSTOM_RULES) all *.rules files found are moved into
# CUSTOM_RULES folder or AUTO_RULES folder (0 = auto, 1 = custom).
for rule in glob("%s/*.rules" % RULES):
    shutil.move(rule, [AUTO_RULES, CUSTOM_RULES][to_bool(settings.get('custom_rules'))])

# Last but not least, replacing CUSTOM_RULES with the new key ENABLED_RULES
del settings['custom_rules']
settings.set('enabled_rules', ['auto', 'custom'][to_bool(settings.get('custom_rules'))])

# Storing the changes
settings.write()