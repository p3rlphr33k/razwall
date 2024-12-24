#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2005-2016 Endian S.p.A. <info@endian.com>                  |
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
#

"""
:::mod::: openvpn-access-import - import an openvpn configuration into efw

:::synposis::: This script imports an OpenVPN client configuration into efw
"""

import os
import sys
import pycurl
import xmlrpclib
import subprocess
import string
from endian.data.ds import DataSource
from endian.core.logger import logging, logger, debug
from optparse import OptionParser

CONFIG_DIR = '/var/efw/openvpnclients'

# Exit-Codes
ERR_USAGE = 1
ERR_SSL = 2
ERR_CONN = 3
ERR_PROFILE = 4
ERR_CONFIGURATION = 5
ERR_EXCEPTION = 6


class OpenVPNAccessParser(object):
    """
    This class parses the configuration that is returned
    by the OpenVPN Access Server via xml-rpc.
    """

    def __init__(self, text):
        """
           :param text: the configuration
           :type text: string
           :rtype: void
        """
        self.text = text
        self.text_lines = str(text).split("\n")
        self.options = {}

    def parse(self):
        """
           This function parses the configuration string and writes it
           into a dictionary.

           :rtype: void
        """
        multiline = False
        multilinekey = ""
        multilinecontent = ""
        for line in self.text_lines:
            line = line.strip()
            if line.startswith('</') and line.endswith('>'):
                self.options[multilinekey] = multilinecontent
                multiline = False
                multilinekey = ""
                multilinecontent = ""
                continue
            elif line.startswith('<') and line.endswith('>'):
                multiline = True
                multilinecontent = ""
                multilinekey = line[1:-1]
                continue
            if not multiline:
                parts = line.split(' ')
                value = ""
                if len(parts) > 1:
                    value = string.join(parts[1:], ' ')
                if parts[0] in self.options:
                    if type([]) != self.options[parts[0]]:
                        self.options[parts[0]] = [self.options[parts[0]]]
                    self.options[parts[0]].append(value)
                else:
                    self.options[parts[0]] = value
            else:
                multilinecontent += "%s\n" % line

    def is_generic(self):
        """
           This function checks whether a generic configuration is
           being used - efw requires non-generic configurations.

           :rtype: boolean
        """
        if "# OVPN_ACCESS_SERVER_GENERIC=1" in self.text_lines:
            return True
        return False

    def get_configuration(self):
        """
           This function returns a dictionary with the configuration
           options.

           :rtype: dict
        """
        return self.options


class OpenVPNClientConfigurationWriter(object):
    """
    This class takes a configuration dictionary as return by the
    OpenVPNAccessParser.get_configuration() method and writes it
    into an efw-compatible format.
    """

    DEFAULTS = {
        'BRIDGE': 'GREEN',
        'BLOCKDHCP': 'on',
        'ENABLED': 'off',
        'NAT_OUT': 'off',
        'HTTP_PROXY': '',
        'PROXY_PORT': '8080',
        'PROXY_SERVER': '',
        'PROXY_NTLM': 'off',
        'ROUTETYPE': 'routed',
        'AUTH_CERT': 'off',
        'AUTH_USERPASS': 'off',
        'PROTOCOL': 'udp',
        'AUTH_TLS': 'off'
    }
    KEYMAPPING = {
        'remote': 'REMOTES',
        'dev-type': 'DEV_TYPE',
        'dev': 'DEVICE',
        'comp-lzo': 'COMP_LZO',
        'auth-user-pass': 'AUTH_USERPASS',
        'key-direction': 'TLS_DIRECTION'
    }
    VALUES = {
        'REMARK': '',
        'NAME': ''
    }

    CERT_FILES = ['ca', 'cert', 'key']
    CREDENTIALS = ['username', 'password']

    def __init__(self, configuration):
        """
           :param configuration: the configuration dictionary
           :type configuration: dict
           :rtype: void
        """
        self.configuration = configuration
        name = ''
        if 'NAME' in configuration:
            name = configuration['NAME']
        elif 'remote' in configuration:
            if isinstance(configuration['remote'], list):
                remote = configuration['remote'][0]
            else:
                remote = configuration['remote']
            name = remote.split(' ')[0].lower()

        if name == '':
            self.configuration = {}
            return

        realname = ""
        chars = string.letters + string.digits
        for char in name:
            if char in chars:
                realname += char.lower()
        if os.path.exists("%s/%s" % (CONFIG_DIR, realname)):
            i = 0
            while True:
                if not os.path.exists("%s/%s%s" % (CONFIG_DIR, realname, i)):
                    realname = "%s%s" % (realname, i)
                    break
                i += 1
        self.configuration['NAME'] = realname

        for key, value in self.VALUES.iteritems():
            if key in configuration:
                self.VALUES[key] = configuration[key]
            else:
                self.VALUES[key] = remote

    def write(self):
        """
           This method writes the configuration to the disk in a format
           that Endian UTM Appliances can understand.

           :rtype: boolean
        """
        if len(self.configuration) == 0:
            return False
        for key, value in self.DEFAULTS.iteritems():
            self.VALUES[key] = value
        for key, value in self.configuration.iteritems():
            if key in self.KEYMAPPING:
                if isinstance(value, list):
                    val = string.join(value, ',')
                else:
                    val = value
                if key == 'remote':
                    val = val.replace(' ', ':')
                if key == 'auth-user-pass' and value not in ['off', 'no']:
                    val = 'on'
                if value == 'no':
                    val = 'off'
                elif value == 'yes':
                    val = 'on'
                self.VALUES[self.KEYMAPPING[key]] = val
            elif key == 'tls-auth':
                self.VALUES['AUTH_TLS'] = 'on'
        if ('ca' in self.configuration and 'cert' in self.configuration
                and 'key' in self.configuration):
            self.VALUES['AUTH_CERT'] = 'on'
        try:
            os.makedirs("%s/%s" % (CONFIG_DIR, self.VALUES['NAME']))
            # subprocess.call(['/bin/chown','nobody.nobody',
            #                 "%s/%s" %(CONFIG_DIR,self.VALUES['NAME'])])
        except Exception, e:
            debug(str(e))
            return False
        if not self.__write_files():
            try:
                os.rmdir("%s/%s" % (CONFIG_DIR, self.VALUES['NAME']))
            except Exception, e:
                debug(str(e))
            return False
        ds = DataSource('openvpnclients/%s' % self.VALUES['NAME']).settings
        for key, value in self.VALUES.iteritems():
            ds[key] = value
        ds.write()
        return True

    def __write_files(self):
        """
           This method writes the certificates to the disk in a format
           that Endian UTM Appliances can understand.

           :rtype: boolean
        """
        filecontent = {}
        filename = "%s/%s/certs.pem" % (CONFIG_DIR, self.VALUES['NAME'])
        caname = '%s/%s/ca.pem' % (CONFIG_DIR, self.VALUES['NAME'])
        convert = True
        for file in self.CERT_FILES:
            if file in self.configuration:
                filecontent[file] = self.configuration[file]
        if 'ca' not in filecontent:
            debug('Error: CA not found')
            return False
        try:
            f = open(caname, 'w')
            f.write(filecontent['ca'])
            f.close()
        except Exception, e:
            debug(str(e))
            return False
        if len(filecontent) == 1:
            convert = False
        content = string.join(filecontent.values(), "\n")
        try:
            f = open(filename, 'w')
            f.write(content)
            f.close()
        except Exception, e:
            debug(str(e))
            return False
        # Convert to PCKS#12 if necessary
        if convert:
            convertname = filename.split('.')[0] + '.p12'
            debug("Converting %s to %s" % (filename, convertname))
            cmd = ["/usr/bin/openssl",
                   "pkcs12",
                   "-export",
                   "-in",
                   filename,
                   "-out",
                   convertname,
                   "-password",
                   "pass:"]
            try:
                c = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
                c.communicate()
                os.unlink(filename)
                os.unlink(caname)
                os.chmod(convertname, 0600)
            except Exception, e:
                debug(str(e))
                if os.path.exists(convertname):
                    os.unlink(convertname)
                return False
        i = 0
        credentialname = "%s/%s/credentials" % (CONFIG_DIR, self.VALUES['NAME'])
        tlsname = "%s/%s/tls.key" % (CONFIG_DIR, self.VALUES['NAME'])
        for key in self.CREDENTIALS:
            try:
                if key in self.configuration:
                    if i == 0:
                        f = open(credentialname, 'w')
                    else:
                        f = open(credentialname, 'a')
                    f.write("%s\n" % self.configuration[key])
                    f.close()
                    os.chmod(credentialname, 0600)
                    # subprocess.call(['/bin/chown','nobody.nobody',
                    #                 credentialname])
            except Exception, e:
                debug(str(e))
                return False
            i += 1
        try:
            if 'tls-auth' in self.configuration:
                f = open(tlsname, 'w')
                f.write(self.configuration['tls-auth'])
                f.close()
                os.chmod(tlsname, 0600)
            # subprocess.call(['/bin/chown','nobody.nobody', caname])
        except Exception, e:
            if os.path.exists(filename):
                os.unlink(filename)
            if convert and os.path.exists(convertname):
                os.unlink(convertname)
            if os.path.exists(credentialname):
                os.unlink(credentialname)
            if os.path.exists(tlsname):
                os.unlink(tlsname)
            debug(str(e))
            return False
        return True


class SSLConnectionChecker(object):
    """
    This class provides methods to check whether an SSL connection is
    using a valid SSL certificate or not.
    """

    def check_connection(self, address):
        """
           This method checks whether the SSL certificate used by the
           server is valid.

           :param address: address for the connection
           :type address: string
           :rtype: boolean
        """
        try:
            debug('Checking validity of SSL certificate')
            c = pycurl.Curl()
            c.setopt(pycurl.URL, address)
            c.setopt(pycurl.FOLLOWLOCATION, 1)
            c.setopt(pycurl.CONNECT_ONLY, 1)
            c.perform()
        except pycurl.error, e:
            debug(str(e))
            sys.exit(ERR_SSL)
            debug('SSL certificate validation failed')
            return False
        debug('SSL certificate is valid')
        return True

if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option("-o", "--host", dest="host", help="the hostname")
    parser.add_option("-s", "--no-ssl-check", action="store_true", dest="no_ssl",
                      help="if enabled the SSL certificate will not be checked for validity")
    parser.add_option("-u", "--user", dest="user",
                      help="the username, password will be asked per prompt")
    parser.add_option("-d", "--debug", action="store_true", dest="debug", help="enable debug mode")
    parser.add_option("-n", "--name", dest="name", help="use this name for the connection")
    parser.add_option("-r", "--remark", dest="remark", help="use this remark for the connection")

    (options, args) = parser.parse_args()
    if options.debug:
        logger.setLevel(logging.DEBUG)
    if not (options.user and options.host):
        parser.print_help()
        sys.exit(ERR_USAGE)

    url = ""
    protocol = 'https'
    if options.host.startswith('http://'):
        options.no_ssl = True
        protocol = 'http'
        url = options.host[7:]
    elif options.host.startswith('https://'):
        url = options.host[8:]
    else:
        url = options.host
    try:
        password = raw_input("Enter the password: ")
        connectionstring = "%s://%s:%s@%s" % (
            protocol, options.user, password, url)
        ssl_check = "%s://%s" % (protocol, url)

        if not options.no_ssl:
            c = SSLConnectionChecker()
            if not c.check_connection(ssl_check):
                sys.exit(ERR_SSL)

        # if we are here the connection is a valid SSL connection
        try:
            debug("Connecting to %s" % (connectionstring))
            proxy = xmlrpclib.ServerProxy(connectionstring, allow_none=True)
            result = proxy.GetAutologin()
        except Exception, e:
            sys.stderr.write(str(e))
            sys.exit(ERR_CONN)

        p = OpenVPNAccessParser(result)
        if p.is_generic():
            sys.exit(ERR_PROFILE)
        p.parse()
        configuration = p.get_configuration()
        if options.name:
            configuration['NAME'] = options.name
        if options.remark:
            configuration['REMARK'] = options.remark
        w = OpenVPNClientConfigurationWriter(configuration)
        success = w.write()
        if not success:
            sys.exit(ERR_CONFIGURATION)
    except SystemExit, e:
        sys.exit(e.code)
    except Exception, e:
        sys.exit(ERR_EXCEPTION)
