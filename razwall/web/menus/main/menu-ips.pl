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

my %subipshash = ();
my $subips = \%subipshash;


$subips->{'01.configuration'} = {
    'caption' => _('Intrusion Prevention System'),
    'uri' => '/manage/ips',
    'title' => _('Intrusion Prevention System'),
    'helpuri' => 'services.html#intrusion-prevention-system',
    'enabled' => 1,
};
$subips->{'02.rules'} = {
    'caption' => _('Rules'),
    'uri' => '/manage/ips/rules',
    'title' => _('Intrusion Prevention rules'),
    'helpuri' => 'services.html#rules',
    'enabled' => 1,
};
$subips->{'03.editor'} = {
    'caption' => _('Editor'),
    'uri' => '/manage/ips/editor',
    'title' => _('Intrusion Prevention editor'),
    'helpuri' => 'services.html#editor',
    'enabled' => 1,
};

my $item = {
    'caption' => _('Intrusion Prevention'),
    'enabled' => 1,
    'subMenu' => $subips,
};

register_menuitem('04.services', '05.ids', $item);

1;
