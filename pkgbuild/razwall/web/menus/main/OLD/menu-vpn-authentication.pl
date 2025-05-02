#!/usr/bin/perl
#
# +-----------------------------------------------------------------------------+
# | Endian Firewall                                                             |
# +-----------------------------------------------------------------------------+
# | Copyright (c) 2005-2013 Endian                                              |
# |         Endian GmbH/Srl                                                     |
# |         Bergweg 41 Via Monte                                                |
# |         39057 Eppan/Appiano                                                 |
# |         ITALIEN/ITALIA                                                      |
# |         info@endian.it                                                      |
# |                                                                             |
# | This program is free software; you can redistribute it and/or               |
# | modify it under the terms of the GNU General Public License                 |
# | as published by the Free Software Foundation; either version 2              |
# | of the License, or (at your option) any later version.                      |
# |                                                                             |
# | This program is distributed in the hope that it will be useful,             |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of              |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               |
# | GNU General Public License for more details.                                |
# |                                                                             |
# | You should have received a copy of the GNU General Public License           |
# | along with this program; if not, write to the Free Software                 |
# | Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. |
# | http://www.fsf.org/                                                         |
# +-----------------------------------------------------------------------------+
#

my $vpnconnection = {
    'caption' => _('VPN connections'),
    'enabled' => 1,
    'uri' => '/manage/vpnauthentication/connection',
    'title' => _('VPN connections'),
    'helpuri' => 'status.html#vpn-connections',
};

my %subauthenticationhash = ();
my $subauthentication = \%subauthentication;

$subauthentication->{'01.users'} = {
	'caption' => _('Users'),
	'enabled' => 1,
	'uri' => '/manage/vpnauthentication/user',
	'helpuri' => 'vpn/authentication.html#users',
	'title' => _('Users')
};

my $authenticationmenu = {
	'caption' => _('Authentication'),
	'enabled' => 1,
	'subMenu' => $subauthentication,
	'helpuri' => 'vpn/authentication.html#authentication'
};

register_menuitem('07.vpn', '04.authentication', $authenticationmenu);
register_menuitem('02.status', '06.vpnconnection', $vpnconnection);
