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

my %subinterfaceshash = ();
my $subinterfaces = \%subinterfaceshash;
$subinterfaces->{'01.uplinkeditor'} = {'caption' => _('Uplink editor'),
			      'uri' => '/cgi-bin/uplinkeditor.cgi',
			      'title' => _('Uplink manager'),
			      'enabled' => 1,
			      'helpuri' => 'network.html#uplink-editor',
			      };
$subinterfaces->{'02.vlan'} = {'caption' => _('VLANs'),
			      'uri' => '/cgi-bin/vlanconfig.cgi',
			      'title' => _('VLAN manager'),
			      'enabled' => 1,
			      'helpuri' => 'network.html#vlans',
			      };

my $item = {
    'caption' => _('Interfaces'),
    'enabled' => 1,
    'subMenu' => $subinterfaces,
};

register_menuitem('03.network', '07.interfaces', $item);

1;
