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

my %subroutinghash = ();
my $subrouting = \%subroutinghash;

$subrouting->{'01.simple'} = {
    'caption' => _('Static Routing'),
    'enabled' => 1,
    'uri' => '/cgi-bin/routing.cgi',
    'title' => _('Static Routing Editor'),
    'helpuri' => 'network.html#static-routing',
};

$subrouting->{'02.policy'} = {
    'caption' => _('Policy Routing'),
    'enabled' => 1,
    'uri' => '/cgi-bin/policy_routing.cgi',
    'title' => _('Policy Routing Editor'),
    'helpuri' => 'network.html#policy-routing',
};

my $item = {
    'caption' => _('Routing'),
    'enabled' => 1,
    'subMenu' => $subrouting,
};

register_menuitem('03.network', '06.routing', $item);

1;
