#!/usr/bin/env python
# encoding: utf-8
"""
squid-samba-changetrustpw.py

Created by Raphael Lechner on 2007-03-23.
Copyright (c) 2007 Endian. All rights reserved.
"""

import sys
import os
from os import system as run
SETTINGS='/var/efw/proxy/settings'

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
        pass
    return config


def main():
    try:
        config=getconfig(SETTINGS)
        if config['LDAP_TYPE'] == "ADS" and config['AD_GROUP_SELECTIONS'] == "on" and config['AUTH_METHOD'] == "ntlm":
            run("net ads changetrustpw")
    except:
        pass

if __name__ == '__main__':
	main()

