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

my %subeventhash = ();
my $subevent = \%subeventhash;


$subevent->{'01.configuration'} = {
    'caption' => _('Configuration'),
    'uri' => '/manage/notifications',
    'title' => _('Event notification: Configuration'),
    'helpuri' => 'system.html#configuration',
    'enabled' => 1,
};
$subevent->{'02.events'} = {
    'caption' => _('Events'),
    'uri' => '/manage/notifications/events',
    'title' => _('Event notifications: Events'),
    'helpuri' => 'system.html#events',
    'enabled' => 1,
};

my $item = {
    'caption' => _('Event notifications'),
    'enabled' => 1,
    'subMenu' => $subevent,
};

register_menuitem('01.system', '03.notifications', $item);

1;
