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

import os
import sys
import iplib
import glob
import subprocess
import traceback
import time
from optparse import OptionParser

from endian.core.settingsfile import SettingsFile
from endian.core.logger import debug, error, logger, logging
from endian.data.ds import DataSource
from endian.datatypes.network import CIDR
from endian.validators.boolean import to_bool
from endian.job.engine_control import send_cmd_to_engine

CONFIGBASE = '/var/efw/ethernet/settings'
CLIENT_CONFIG_DIR = '/var/efw/openvpnclients/'
DEFAULT = '/var/efw/openvpnclients/default/'
IP_PATH = '/sbin/ip'


def get_pushed_routes(options):
    ret = []
    routecount = len(filter(lambda x: x.startswith('route_network'), os.environ))

    for i in range(routecount):
        net = os.environ.get("route_network_%s" % (i + 1))
        mask = os.environ.get("route_netmask_%s" % (i + 1))
        if net is None or mask is None:
            continue
        ret.append(CIDR(net, mask).subnet)

    ret.append(CIDR(options.netcidr).subnet)
    return ret


def get_local_routes(config_value):
    ret = []
    for i in ['GREEN_IPS', 'BLUE_IPS', 'ORANGE_IPS']:
        for cidr in config_value[i].split(','):
            try:
                ret.append(CIDR(cidr).subnet)
            except:
                # don't stop when there is an invalid ip address in settings file
                pass

    ds = DataSource('routing')
    if ds.config is None:
        return ret
    for i in ds.config:
        if not to_bool(i.enabled):
            continue
        if i.dst_ip == '':
            continue
        if i.src_ip != '':
            continue
        try:
            if '/' not in i.dst_ip:
                ret.append(CIDR(i.dst_ip, '32').subnet)
            else:
                ret.append(CIDR(i.dst_ip).subnet)
        except:
            # don't stop when there is an invalid ip address in settings file
            pass

    return ret


def get_client_config(options):
    default = SettingsFile(DEFAULT + 'settings')
    ret = {}
    if options.command == 'remove':
        search = "%s/*/data" % (CLIENT_CONFIG_DIR)
    else:
        search = "%s/*/settings" % (CLIENT_CONFIG_DIR)
        ret.update(default.settings())
    debug("Searching for '%s' containing 'DEVICE=%s'" % (search, options.tap))
    for sf in glob.glob(search):
        if sf.startswith(DEFAULT):
            continue
        s = SettingsFile(sf)
        debug(s.settings())
        if not to_bool(s.get('ENABLED', 'off')):
            debug("'%s' is DISABLED" % sf)
            continue
        if s.get('DEVICE', '') != options.tap:
            continue
        ret.update(s.settings())
        return ret
    return {}


def remove_config(config_value, options):
    debug("Remove network configuration for device %s" % options.tap)
    for i in config_value['PUSHED_ROUTES']:
        subprocess.call([IP_PATH, 'rule', 'del', 'to', i])

    if config_value.get('ROUTETYPE', 'routed') == 'bridged':
        zone = config_value.get('BRIDGE', 'GREEN')
        zone = zone.upper()
        bridge = config_value.get(zone + '_DEV', '')

        # This is necessary in order to allow openvpn to remove *this*
        # ip address without producing an error, which would exit openvpn.
        subprocess.call([IP_PATH, 'addr', 'add', options.cidr, 'dev', options.tap])
        if bridge == '':
            error("Cannot remove device '%s' from a bridge. No bridge specified for zone '%s'" % (options.tap, zone))
            return 0
        debug("Remove bridging configuration")
        subprocess.call([IP_PATH, 'addr', 'del', options.cidr, 'dev', bridge])
        subprocess.call([IP_PATH, 'route', 'flush', 'cache'])
        debug("Done")


def set_live_data(name):
    debug("Save live data of connection %s" % name)
    name = name.lower()
    s = SettingsFile("%s/%s/settings" % (CLIENT_CONFIG_DIR, name))
    d = SettingsFile("%s/%s/data" % (CLIENT_CONFIG_DIR, name))
    d.update(s.settings())
    d.set('TIMESTAMP', time.time())
    d.write()
    debug("Saved on '%s'" % d['TIMESTAMP'])


def apply_config(config_value, options):
    debug("Apply network configuration for device %s" % options.tap)

    for i in config_value['PUSHED_ROUTES']:
        subprocess.call([IP_PATH, 'rule', 'del', 'to', i])
        subprocess.call([IP_PATH, 'rule', 'add', 'prio', '5', 'to', i, 'lookup', 'main'])

    # There is no openvpn client configured with this tap device
    # so do not try to apply it's configuration.
    if config_value.get('DEVICE', '') != options.tap:
        error("VPN client configuration of device '%s' not found. Do not apply configuration." % options.tap)
        subprocess.call([IP_PATH, 'route', 'flush', 'cache'])
        return 0

    debug("Applying vpn client configuration of connection '%s'." % config_value.get('NAME', 'unknown'))

    # sync bridge setup
    send_cmd_to_engine("restart bridges")

    if config_value.get('ROUTETYPE', 'routed') == 'bridged':
        zone = config_value.get('BRIDGE', 'GREEN')
        zone = zone.upper()
        bridge = config_value.get(zone + '_DEV', '')
        if bridge == '':
            error("Cannot join device '%s' to a bridge. No bridge specified for zone '%s'" % (options.tap, zone))
            return 0

        # This is necessary in order to allow openvpn to install
        # pushed routing configuration which use this subnet
        # as gateway. If the ip address is lost, the route for
        # this subnet will also be removed and the routing is broken.
        debug("Move vpn ip '%s' to %s bridge" % (options.cidr, zone))
        subprocess.call([IP_PATH, 'addr', 'add', options.cidr, 'dev', bridge])
        subprocess.call([IP_PATH, 'route', 'flush', 'cache'])
        debug("Done")

    return 0


class Options:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)


def parse_arguments():
    options = Options(tap='', ip='', cidr='', netcidr='', mask_or_remote_ip='', command='')

    usage = "usage: %prog <options> <device> <mtu> <mru> <local_ip> <local_netmask|remote_ip> [init|restart]"
    parser = OptionParser(usage)

    parser.add_option(
        "-d", "--debug", dest="debug",
        action="store_true",
        help="be more verbose", default=False)
    parser.add_option(
        "-r", "--remove", dest="remove",
        action="store_true",
        help="remove bride config", default=False)
    parser.add_option(
        "-a", "--apply", dest="apply",
        action="store_true",
        help="apply bride config", default=False)
    (flags, args) = parser.parse_args()

    if len(args) <= 5:
        parser.error("To few arguments! Need to specify at least <device> <mtu> <mru> <local_ip> <local_netmask|remote_ip>")
        sys.exit(1)

    if flags.debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)

    options.tap = args[0]
    options.ip = args[3]
    options.mask_or_remote_ip = args[4]

    try:
        cidrobj = iplib.CIDR(options.ip, options.mask_or_remote_ip)
        bits = cidrobj.get_netmask().get_bits()
        if int(bits) < 32:
            net = cidrobj.get_network_ip().get()
        else:
            net = options.ip
        options.cidr = "%s/%s" % (cidrobj.get_ip().get(), bits)
        options.netcidr = "%s/%s" % (net, bits)
    except ValueError:
        # 'mask_or_remote_ip' could be an IP address
        try:
            bits = 32
            cidrobj = iplib.CIDR(options.mask_or_remote_ip, bits)
            net = options.mask_or_remote_ip
            options.cidr = "%s/%s" % (cidrobj.get_ip().get(), bits)
            options.netcidr = "%s/%s" % (net, bits)

        except ValueError:
            debug(traceback.format_exc())
            parser.error("Invalid ip or netmask '%s %s'" % (options.ip, options.mask_or_remote_ip))

    if (not flags.remove) and (not flags.apply):
        parser.error("No action selected. Select one of --remove or --apply")
    if flags.remove and flags.apply:
        parser.error("Select one of --remove or --apply")
    if flags.remove:
        options.command = 'remove'
    if flags.apply:
        options.command = 'apply'

    debug("Calculated local ip/cidr: '%s'. net/cidr: '%s'" % (options.cidr, options.netcidr))
    debug("Tool is going to %s the configuration" % options.command)

    return options


def load_config(options):
    config_value = {}
    config_value.update(SettingsFile(CONFIGBASE).settings())
    debug("Config: %s" % config_value)
    conf = get_client_config(options)
    debug("Client config: %s" % conf)
    config_value.update(conf)
    localroutes = get_local_routes(config_value)
    config_value['LOCAL_ROUTES'] = localroutes
    debug("Local routes: %s" % localroutes)
    pushedroutes = [x for x in get_pushed_routes(options) if x not in config_value['LOCAL_ROUTES']]
    config_value['PUSHED_ROUTES'] = pushedroutes
    debug("Pushed routes: %s" % pushedroutes)
    return config_value


def main():
    options = parse_arguments()
    config_value = load_config(options)

    if options.command == 'apply':
        apply_config(config_value, options)
        if 'NAME' in config_value:
            set_live_data(config_value['NAME'])

    elif options.command == 'remove':
        remove_config(config_value, options)

if __name__ == "__main__":
    main()
