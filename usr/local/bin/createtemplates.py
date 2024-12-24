#!/usr/bin/python
#
# Author: Peter Warasin <peter@endian.com>
# Copyright: Endian (c) 2008
# License: GPL
# Date: 2008-07-17
#

from optparse import OptionParser
from endian.job.engine_control import send_cmd_to_engine

def main():
    usage = "usage: %prog <options>"
    parser = OptionParser(usage)
    parser.add_option("-d", "--debug", dest="debug", action="store_true",
                      help="be more verbose", default=False)
    parser.add_option("-f", "--force", dest="force", action="store_true",
                      help="force creation of templates", default=False)
    parser.add_option("-s", "--service", dest="service", metavar="SERVICE",
                      help="Compile only service SERVICE")
    parser.add_option("-c", "--config", dest="config", metavar="FILE",
                      help="use config file FILE")
    parser.add_option("-n", "--dry-run", dest="dryrun", action="store_true", default=False,
                      help="dry run - tell only what would be done, but don't really do it")
    (options, args) = parser.parse_args()

    if options.dryrun:
        options.debug = True
        print "Dry run. Actions will not really be done, "
        "you will see only debug messages printed out what would be done"

    send_cmd_to_engine("restart createtemplates", options=options)

if __name__ == "__main__":
    main()
