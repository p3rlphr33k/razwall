#!/usr/bin/env perl
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2004-2016 S.p.A. <info@endian.com>                         |
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

my %subdnshash = ();
my $subdns = \%subdnshash;
$subdns->{'01.proxy'} = {
    'caption' => _('Proxy configuration'),
    'enabled' => 1,
    'uri' => '/manage/dnsmasq/dnsproxy',
    'title' => _('DNS proxy configuration'),
    'helpuri' => 'proxy/dns.html#dns',
};
$subdns->{'02.local'} = {
    'caption' => _('DNS Routing'),
    'enabled' => 1,
    'uri' => '/manage/dnsmasq/localdomains',
    'title' => _('DNS Proxy - DNS Routing'),
    'helpuri' => 'proxy/dns.html#dns-routing',
};
$subdns->{'03.blackhole'} = {
    'caption' => _('Anti-spyware'),
    'enabled' => 1,
    'uri' => '/manage/dnsmasq/antispyware',
    'title' => _('Anti-spyware - blackhole DNS'),
    'helpuri' => 'proxy/dns.html#anti-spyware',
};


my $item = {
    'caption' => _('DNS'),
    'enabled' => 1,
    'subMenu' => $subdns,
};

my $network = {
    'caption' => _('Edit hosts'),
    'uri' => '/manage/dnsmasq/hosts',
    'title' => _('Host configuration'),
    'enabled' => 1,
    'helpuri' => 'network.html#the-network-menu',
};

register_menuitem('06.proxy', '06.dns', $item);
register_menuitem('03.network', '01.hosts', $network);

1;
