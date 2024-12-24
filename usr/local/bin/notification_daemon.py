#!/usr/bin/python
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2011 Endian                                              |
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

import os
import sys
import inspect
import signal
from endian.core.logger import *
logger = create_logger(name="notifications")

from endian.notifications.plugins.action import Action

modules = []

def conf_reload(signum, frame):
    global modules
    logger.info("Cathed signal %d. Reloading conf" % (signum))
    map(lambda x: x.load_config(), modules)
    return

def find_subclasses(path, cls):
    """
    Find all subclass of cls in py files located below path
    (does look in sub directories)

    @param path: the path to the top level folder to walk
    @type path: str
    @param cls: the base class that all subclasses should inherit from
    @type cls: class
    @rtype: list
    @return: a list if classes that are subclasses of cls
    """

    subclasses=[]

    def look_for_subclass(modulename):
        logger.info("searching %s" % (modulename))
        module=__import__(modulename)

        #walk the dictionaries to get to the last one
        d=module.__dict__
        for m in modulename.split('.')[1:]:
            d=d[m].__dict__

        #look through this dictionary for things
        #that are subclass of Job
        #but are not Job itself
        for key, entry in d.items():
            if key == cls.__name__:
                continue

            try:
                if issubclass(entry, cls):
                    logger.info("Found subclass: "+key)
                    subclasses.append(entry)
            except TypeError:
                #this happens when a non-type is passed in to issubclass. We
                #don't care as it can't be a subclass of Job if it isn't a
                #type
                continue

    for name in os.listdir(path):
        if name.endswith(".pyc") and not name.startswith("__"):
            modulename = name.rsplit('.', 1)[0].replace('/', '.')
            look_for_subclass("endian.notifications.plugins."+modulename)

    return subclasses

def main():
    global modules
    classes = find_subclasses(os.path.dirname(inspect.getfile(Action)), Action)
    #lets create an instance of the first class
    modules = [i(logger) for i in classes]

    signal.signal(signal.SIGUSR1, conf_reload)

    while True:
        try:
            line = sys.stdin.readline()
        except IOError:
            continue
        if not line:
            break
        logger.info("Processing log: %s" % line.strip())
        map(lambda x: x.process(line), modules)

if __name__ == '__main__':
    main()
