#!/usr/bin/python
#
#        +--------------------------------------------------------------------+
#        | Endian Firewall                                                    |
#        +--------------------------------------------------------------------+
#        | Copyright (c) 2005-2008 Endian                                     |
#        |         Endian GmbH/Srl                                            |
#        |         Bergweg 41 Via Monte                                       |
#        |         39057 Eppan/Appiano                                        |
#        |         ITALIEN/ITALIA                                             |
#        |         info@endian.it                                             |
#        |                                                                    |
#        | This program is free software; you can redistribute it and/or      |
#        | modify it under the terms of the GNU General Public License        |
#        | as published by the Free Software Foundation; either version 2     |
#        | of the License, or (at your option) any later version.             |
#        |                                                                    |
#        | This program is distributed in the hope that it will be useful,    |
#        | but WITHOUT ANY WARRANTY; without even the implied warranty of     |
#        | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the      |
#        | GNU General Public License for more details.                       |
#        |                                                                    |
#        | You should have received a copy of the GNU General Public License  |
#        | along with this program; if not, write to the Free Software        |
#        | Foundation, Inc., 59 Temple Place - Suite 330, Boston,             |
#        | MA 02111-1307, USA.                                                |
#        | http://www.fsf.org/                                                |
#        +--------------------------------------------------------------------+
#

"""Migration: Switch from cron to anacron

Old versions of snort used cron to fetch the snort rules periodically.
This generated a high bandwidth load on Emerging Threat servers (#1140),
hence, anacron is now used.

"""

import os

os.system("/usr/local/bin/restartsnortrules --norestart")
