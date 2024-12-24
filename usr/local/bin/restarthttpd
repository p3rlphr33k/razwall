#!/usr/bin/python
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

from optparse import OptionParser
from endian.job.engine_control import send_cmd_to_engine

def main():
    usage = "usage: %prog <options>"
    parser = OptionParser(usage)    
    parser.add_option("-d", "--debug", dest="debug", action="store_true",
                      help="Be more verbose", default=False)
    parser.add_option("-f", "--force", dest="force", action="store_true",
                      help="Forces restart", default=False)
    parser.add_option("-r", "--reload", dest="reload", action="store_true",
                      help="reload httpd", default=False)
    parser.add_option("-g", "--update-groups", dest="updategroups", action="store_true",
                      help="Update the httpd groups file", default=False)
    (options, args) = parser.parse_args()
    
    send_cmd_to_engine("restart httpd", options=options)

if __name__ == "__main__":
    main()
