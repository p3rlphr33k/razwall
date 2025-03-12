#!/usr/bin/perl
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2006 Endian                                              |
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

my %subqoshash = ();
my $subqos = \%subqoshash;


$subqos->{'01.devices'} = {
    'caption' => _('Devices'),
    'uri' => '/manage/qos/devices',
    'title' => _('Quality of Service') . ': ' . _('Devices'),
    'helpuri' => 'services.html#devices',
    'enabled' => 1,
};
$subqos->{'02.classes'} = {
    'caption' => _('Classes'),
    'uri' => '/manage/qos/classes',
    'title' => _('Quality of Service') . ': ' . _('Classes'),
    'helpuri' => 'services.html#classes',
    'enabled' => 1,
};
$subqos->{'03.rules'} = {
    'caption' => _('Rules'),
    'uri' => '/manage/qos/rules',
    'title' => _('Quality of Service') . ': ' . _('Rules'),
    'helpuri' => 'services.html#qos-rules',
    'enabled' => 1,
};

my $item = {
    'caption' => _('Quality of Service'),
    'enabled' => 1,
    'subMenu' => $subqos,
};

register_menuitem('04.services', '10.qos', $item);

1;
