#!/usr/bin/perl
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2016 S.p.A. <info@endian.com>                              |
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

my %subdhcphash = ();
my $subdhcp = \%subdhcphash;

$subdhcp->{'01.settings'} = {'caption' => _('Server configuration'),
    'uri' => '/manage/dhcp/settings',
    'title' => _('DHCP Server configuration'),
    'enabled' => 1,
    'helpuri' => 'services.html#dhcp-server',
};

$subdhcp->{'02.fixed_leases'} = {
    'caption' => _('Fixed leases'),
    'uri' => '/manage/dhcp/fixed_leases',
    'title' => _('DHCP fixed leases'),
    'enabled' => 1,
    'helpuri' => 'services.html#dhcp-server',
};

$subdhcp->{'03.leases'} = {
    'caption' => _('Dynamic leases'),
    'uri' => '/manage/dhcp/leases',
    'title' => _('DHCP dynamic leases'),
    'enabled' => 1,
    'helpuri' => 'services.html#dhcp-server',
};

my $item = {
    'caption' => _('DHCP Server'),
    'enabled' => 1,
    'subMenu' => $subdhcp,
};

register_menuitem('04.services', '01.dhcp', $item);

1;
