#!/usr/bin/perl
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

my $item = {
    'caption' => _('OpenVPN client (Gw2Gw)'),
    'enabled' => 1,
    'uri' => '/cgi-bin/openvpnclient.cgi',
    'title' => _('OpenVPN') . ' - ' . _('Virtual Private Networking'),
    'helpuri' => 'vpn/client.html#openvpn-client-gw2gw',
};

register_menuitem('07.vpn', '01.openvpnclient', $item);

1;