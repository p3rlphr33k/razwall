# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2012-2013 Endian                                           |
# |         Endian GmbH/Srl                                                  |
# |         Bergweg 41 Via Monte                                             |
# |         39057 Eppan/Appiano                                              |
# |         ITALIEN/ITALIA                                                   |
# |         info@endian.com                                                  |
# |                                                                          |
# | efw-ipsec is free software: you can redistribute it and/or modify it     |
# | under the terms of GNU General Public License (GPL) version 2.0          |
# | when released with the Community edition                                 |
# | or the GNU Lesser General Public License (LGPL) version 2.1              |
# | when released with the Enterprise edition.                               |
# |                                                                          |
# | efw-ipsec is distributed in the hope that it will be useful,             |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the             |
# | GNU General Public License for more details or the                       |
# | GNU Lesser General Public License for more details.                      |
# |                                                                          |
# | You should have received a copy of the license along with efw-ipsec.     |
# | If not, see <http://www.gnu.org/licenses/>.                              |
# +--------------------------------------------------------------------------+
require 'header.pl';
require '/razwall/web/cgi-bin/endianinc.pl';

my $ipsec = ['charon', '/var/run/strongswan/charon.pid', ''];
register_status(_('VPN (IPsec)'), $ipsec);