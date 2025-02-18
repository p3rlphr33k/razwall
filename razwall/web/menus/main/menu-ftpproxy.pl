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

my %subftphash = ();
my $subftp = \%subftphash;

$subftp->{'01.proxy'} = {
    'caption' => _('Proxies'),
    'uri' => '/cgi-bin/frox.cgi',
    'title' => _('FTP: virus scanner'),
    'enabled' => 1,
    'helpuri' => 'proxy/ftp.html#ftp',
};

$item = {
    'caption' => _('FTP'),
    'enabled' => 1,
    'subMenu' => $subftp
};

register_menuitem('06.proxy', '04.ftp', $item);

1;
