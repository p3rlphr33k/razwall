#!/usr/bin/perl
#
#+-----------------------------------------------------------------------------+
#| Endian Authenticaton Layer                                                  |
#+-----------------------------------------------------------------------------+
#| Copyright (c) 2005-2011 Endian GmbH/Srl                                     |
#|      Endian GmbH/Srl                                                        |
#|      Bergweg 41 Via Monte                                                   |
#|      39057 Eppan/Appiano                                                    |
#|      ITALIEN/ITALIA                                                         |
#|      info@endian.it                                                         |
#+-----------------------------------------------------------------------------+
#| This program is free software; you can redistribute it and/or               |
#| modify it under the terms of the GNU General Public License                 |
#| as published by the Free Software Foundation; either version 2              |
#| of the License, or (at your option) any later version.                      |
#|                                                                             |
#| This program is distributed in the hope that it will be useful,             |
#| but WITHOUT ANY WARRANTY; without even the implied warranty of              |
#| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               |
#| GNU General Public License for more details.                                |
#|                                                                             |
#| You should have received a copy of the GNU General Public License           |
#| along with this program; if not, write to the Free Software                 |
#| Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. |
#| http://www.fsf.org/                                                         |
#+-----------------------------------------------------------------------------+

my %subopenvpnhash = ();
my $subopenvpn = \%subopenvpnhash;

$subopenvpn->{'01.server'} = {'caption' => _('Server configuration'),
    'uri' => '/manage/openvpn',
    'title' => _('OpenVPN').' - '._('Virtual Private Networking'),
    'enabled' => 1,
    'helpuri' => 'vpn/server.html#openvpn-server',
};

$subopenvpn->{'99.download'} = {
    'caption' => _('VPN client download'),
    'uri' => '/cgi-bin/download-vpnclient.cgi',
    'title' => _('VPN client download'),
    'enabled' => 1,
    'helpuri' => 'vpn/server.html#vpn-client-download',
};

my $item = {
    'caption' => _('OpenVPN server'),
    'enabled' => 1,
    'subMenu' => $subopenvpn,
};

register_menuitem('07.vpn', '00.openvpnserver', $item);

1;
