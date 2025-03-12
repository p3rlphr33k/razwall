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

my %subeventhash = ();
my $subevent = \%subeventhash;

$subevent->{'01.certificate'} = {
    'caption' => _('Certificates'),
    'uri' => '/manage/ca/certificate',
    'title' => _('Certificates'),
    'helpuri' => 'vpn/certificates.html#certificates',
    'enabled' => 1
};

$subevent->{'02.create_certificate'} = {
    'caption' => _('Generate a certificate'),
    'uri' => '/manage/ca/create_certificate',
    'title' => _('Generate a certificate'),
    'enabled' => 0
};

$subevent->{'03.certificate_authority'} = {
    'caption' => _('Certificate Authority'),
    'uri' => '/manage/ca/certificate_authority',
    'title' => _('Certificate Authority'),
    'helpuri' => 'vpn/certificates.html#certificate-authority',
    'enabled' => 1
};

$subevent->{'04.revoked_certificate'} = {
    'caption' => _('Revoked Certificates'),
    'uri' => '/manage/ca/revoked_certificate',
    'title' => _('Revoked Certificates'),
    'helpuri' => 'vpn/certificates.html#revoked-certificates',
    'enabled' => 1
};

$subevent->{'05.crl'} = {
    'caption' => _('Certificate Revocation List'),
    'uri' => '/manage/ca/crl',
    'title' => _('Certificate Revocation List'),
    'helpuri' => 'vpn/certificates.html#certificate-revocation-list',
    'enabled' => 1
};

my $item1 = {
    'caption' => _('Certificates'),
    'enabled' => 1,
    'helpuri' => 'vpn/authentication.html#authentication',
    'subMenu' => $subevent
};
register_menuitem('07.vpn', '05.ca', $item1);

1;
