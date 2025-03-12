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

my %subportfwhash = ();
my $subportfw = \%subportfwhash;

$subportfw->{'01.dnat'} = {
    'caption' => _('Port forwarding / Destination NAT'),
    'uri' => '/cgi-bin/dnat.cgi',
    'title' => _('Port forwarding / Destination NAT'),
    'enabled' => 1,
    'helpuri' => 'firewall.html#port-forwarding-destination-nat',
};
    
$subportfw->{'02.snat'} = {
    'caption' => _('Source NAT'),
    'uri' => '/cgi-bin/snat.cgi',
    'title' => _('Source Network Address Translation'),
    'enabled' => 1,
    'helpuri' => 'firewall.html#source-nat',
};

$subportfw->{'03.incoming'} = {
    'caption' => _('Incoming routed traffic'),
    'uri' => '/cgi-bin/incoming.cgi',
    'title' => _('Incoming firewall configuration'),
    'enabled' => 1,
    'helpuri' => 'firewall.html#incoming-routed-traffic',
};

my $item = {
    'caption' => _('Port forwarding / NAT'),
    'enabled' => 1,
    'subMenu' => $subportfw,
};
                                                                                                          

register_menuitem('05.firewall', '01.dnat', $item);

1;
