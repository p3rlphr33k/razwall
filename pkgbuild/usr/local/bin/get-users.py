#!/usr/bin/python
# -*- coding: utf-8 -*-
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2006 Endian                                              |
#        |         Endian GmbH/Srl                                                     |
#        |         Bergweg 41 Via Monte                                                 |
#        |         39057 Eppan/Appiano                                                 |
#        |         ITALIEN/ITALIA                                                      |
#        |         info@endian.it                                                      |
#        |                                                                            |
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

import ldap
import os
import sys
from os import popen as run
from endian.core.settingsfile import SettingsFile, SettingsException

# ARGGGGH perl default lang is Posix
os.environ["LANG"] = "en_US.UTF-8"

PROXY_SETTINGS = "/var/efw/proxy/settings"
config_values = {}

config_values.update(SettingsFile(PROXY_SETTINGS))

def get_ldap_users():
    """
    Get User Information from a LDAP/ADS Directory
    """
    try:
        l = ldap.initialize("ldap://%s:%s" % (config_values['LDAP_SERVER'], config_values['LDAP_PORT']))
        l.protocol_version = ldap.VERSION3
        l.set_option(ldap.OPT_REFERRALS,0)
        username = config_values['LDAP_BINDDN_USER']
        username = username.replace("\'", "")
        password  = config_values['LDAP_BINDDN_PASS']
        l.simple_bind_s(username, password)
    except ldap.TIMEOUT, e:
        sys.stderr.write("No Response from LDAP (Timeout)\n")
        return
    except ldap.LDAPError, e:
        sys.stderr.write("LDAP Connection Error: %s\n" % e)
        return
    
    baseDN = config_values['LDAP_BASEDN'].replace("\'", "")
    searchFilter = "(objectClass=%s)" % config_values['LDAP_PERSON_OBJECT_CLASS']    # search for all groups
    users = []
    
    try:
        ldap_result_id = l.search(baseDN, ldap.SCOPE_SUBTREE, searchFilter)
        result_type = ldap.RES_SEARCH_ENTRY
        while 1:                                                            # read all results
            result_type, result_data, result_id = l.result2(ldap_result_id, all=0, timeout=20)
            if (result_data == []):
                break # if [] is retruned all entries where read
            elif result_type == ldap.RES_SEARCH_ENTRY: # onl search results should be returned
                if result_data[0][0] == "":
                    continue
                users.append(result_data[0][0])
    
    except ldap.TIMEOUT, e:
        sys.stderr.write("No Response from LDAP (Timeout)\n")
        return
    except ldap.LDAPError, e:
        sys.stderr.write("LDAP Connection Error: %s\n" % e)
        return
    
    users.sort(lambda x, y: cmp(x.lower(),y.lower()))
    
    for user in users:            # print all users
        print user
    
    l.unbind_s()
    

def get_ntlm_users():
    """
    Get Informations from a NT Domain -> winbind
    """
    cmd="wbinfo -t"
    lines = os.popen(cmd).readlines()
    if not 'checking the trust secret via RPC calls failed\n' in lines:
        cmd='wbinfo -u'
        
        users = os.popen(cmd).readlines()
        users.sort(lambda x, y: cmp(x.lower(),y.lower()))
        
        for line in users:
            # do not show the smaba builtin groups!!!
            if not line.startswith("BUILTIN+"):
                line = line.split( "+", 1 )
                items = len(line) - 1
                print line[items].strip("\n")

if ( config_values['AUTH_METHOD'] == "ntlm" ):
    get_ntlm_users()
elif ( config_values['AUTH_METHOD'] == "ldap" ):
    get_ldap_users()

