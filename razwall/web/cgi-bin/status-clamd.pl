#!/usr/bin/perl

#+---------------------------------------------------------------------------+
#| Endian Hotspot                                                            |
#+---------------------------------------------------------------------------+
#| Copyright (c) 2005-2006 Endian GmbH/Srl                                   |
#|      Endian GmbH/Srl                                                      |
#|      Bergweg 41 Via Monte                                                 |
#|      39057 Eppan/Appiano                                                  |
#|      ITALIEN/ITALIA                                                       |
#|      info@endian.it                                                       |
#+---------------------------------------------------------------------------+
#| This program is proprietary software; you are not allowed to redistribute |
#| and/or modify it.                                                         |
#| This program is distributed in the hope that it will be useful,           |
#| but WITHOUT ANY WARRANTY; without even the implied warranty of            |
#| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                      |
#+---------------------------------------------------------------------------+

require 'header.pl';
require '/razwall/web/cgi-bin/endianinc.pl';

my $clamd = ['clamd', '/var/run/clamav/clamd.pid', ''];
register_status(_('Virus scanner (clamd)'), $clamd);