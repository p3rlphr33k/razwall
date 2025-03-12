#!/usr/bin/env python
# -*- coding: utf-8 -*-
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

"""Script which does creates partitions, filesystems and directory structure of /var on a block device (SD disk)."""

from ConfigParser import ConfigParser
from optparse import OptionParser
from glob import glob
import sys
import tempfile
import rpm
import stat
import os
import random
from pwd import getpwnam
from grp import getgrnam
from endian.core.logger import debug, error, configureLogger
from endian.core.runner import run
from endian.data.container.settings import SettingsFile


HOST_CHARS = '0123456789abcdefghijklmnopqrstuvwxyz'
HOST_LEN = 15

RSYNC_VAR_EFW_CMD = '/usr/local/bin/sync_var_efw.sh'
RSYNC_VAR_EFW_CMD_OPTS = '-i -d "%s/var/efw/"'


def opthandler():
    usage = "usage: %prog <options> <device>"
    parser = OptionParser(usage)
    parser.add_option("-d", "--debug", dest="debug", action="store_true",
                      help="Be more verbose", default=False)
    parser.add_option("-c", "--config", dest="config",
                      metavar="CONFIG",
                      help="config file", default='/etc/formatsd*.conf')
    parser.add_option("-r", "--root", dest="root",
                      metavar="ROOT",
                      help="root mount point", default='/tmp/formatsd')
    parser.add_option("-D", "--no-dir", dest="noDir", action="store_true",
                      help="do not create directory structure",
                      default=False)
    parser.add_option("-S", "--no-sync", dest="noSync", action="store_true",
                      help="do not sync /usr/lib/efw_backup/ to /var/efw/",
                      default=False)
    parser.add_option("-F", "--no-format", dest="noFormat",
                      action="store_true",
                      help="do not create file systems",
                      default=False)
    parser.add_option("-H", "--no-post-hooks", dest="noHooks",
                      action="store_true",
                      help="do not call post hooks",
                      default=False)
    parser.add_option("-p", "--post-hook-dir", dest="postHookDir",
                      metavar="HOOKDIR",
                      help="call the scripts in directory HOOKDIR. default is '/usr/lib/createvar/'",
                      default="/usr/lib/createvar/")
    parser.add_option("-u", "--umount", dest="umount",
                      action="store_true",
                      help="do unmount after creation of partititon",
                      default=False)

    (options, args) = parser.parse_args()
    if len(args) < 1:
        parser.error("Need to specify a device")
    return (options, args)


def readConfig(o):
    ret = {}
    debug("Read configuration")
    config_file = glob(o.config)
    if len(config_file) >= 1:
        config_file = config_file[0]
        debug("Using config file '%s" % config_file)
    else:
        error("No config file found with glob '%s'" % o.config)
        sys.exit(1)

    config = ConfigParser()
    config.read(config_file)

    for sect in config.sections():
        debug("Read section '%s'" % sect)
        item = {}
        item['size'] = None
        item['mp'] = sect
        item['isSwap'] = False
        if sect == 'swap':
            item['isSwap'] = True
        if config.has_option(sect, 'size'):
            item['size'] = str(config.get(sect, 'size'))
        if config.has_option(sect, 'label'):
            label = config.get(sect, 'label')
        else:
            label = sect.upper()
            label = label.replace('/', '')
        item['label'] = label
        ret[sect] = item
    return ret


def deviceUsesP(dev):
    with_p = False
    shortdev = dev.split('/')[2]
    f = open('/proc/partitions')
    for i in f:
        split = i.split()
        if len(split) < 4:
            continue
        if split[3] == shortdev:
            continue
        if split[3].startswith(shortdev):
            if split[3].startswith(shortdev + 'p'):
                with_p = True
                break
    f.close()
    return with_p


def createPartition(dev, table, disk_size):
    debug("Create sfdisk config file")
    sfdisk = tempfile.NamedTemporaryFile(prefix='sfdisk.')
    for (k, v) in table.iteritems():
        type = '83'
        if v.get('isSwap'):
            type = '82'
        line = "%s,%s,%s,\n" % (
            v.get('start'),
            v.get('len'),
            type,
        )
        debug(line)
        sfdisk.write(line)
    sfdisk.flush()
    debug("Output of sfdisk")
    debug("Partition device '%s'" % dev)
    cylinders = disk_size * 1024 * 1204 / CYLINDER_SIZE
    r = run("sfdisk --force -D -uS -H %s -S %s -C %s %s < %s" % (
            HEADS,
            SECTORS,
            cylinders,
            dev,
            sfdisk.name
            ))
    sfdisk.close()
    return (r.returncode == 0)


def calcDevices(dev, table):
    debug("Set device names")
    p = ''
    if deviceUsesP(dev):
        p = 'p'
    i = 1
    for (k, v) in table.iteritems():
        v['dev'] = "%s%s%s" % (dev, p, i)
        i += 1
    debug("Table is now: %s" % table)


def createFs(dev, table):
    debug("Create file systems")
    for (k, v) in table.iteritems():
        part = v.get('dev')
        label = v.get('label')
        if not dev:
            error("Skipped a device!")
            continue
        if v.get('isSwap'):
            debug("Create swap on %s" % part)
            run("mkswap -L %s %s" % (label, part))
            continue
        else:
            debug("Create ext3 fs on %s" % part)
            r = run("mkfs.ext3 -b 4096 -L %s %s" % (label, part))
            if r.returncode != 0:
                return False
            r = run("tune2fs -i 0 -c 0 %s" % part)
            if r.returncode != 0:
                return False
            continue
    return True


def getRam():
    f = open("/proc/meminfo")
    for i in f:
        if i.startswith("MemTotal:"):
            split = i.split()
            size = long(split[1])
            size = long(size / 1024)
            break
    f.close()
    debug("Got a ram size of '%s'" % size)
    return size


def getDiskSize(dev):
    r = run('sfdisk -s %s' % dev)
    if r.returncode != 0:
        return -1
    return long(long(r.getOutput()) / 1024)

HEADS = 128
SECTORS = 32
SECTOR_SIZE = 512  # bytes
CYLINDER_SIZE = HEADS * SECTORS * SECTOR_SIZE

# Notes:
# * since we align partitions on 4 MiB by default, geometry is currently 128
#   heads and 32 sectors (2 MiB) as to have CHS-aligned partition start/end
#   offsets most of the time and hence avoid some warnings with disk
#   partitioning tools
# * we want partitions aligned on 4 MiB as to get the best performance and
#   limit wear-leveling

# align on 4 MiB
PART_ALIGN_S = 4 * 1024 * 1024 / SECTOR_SIZE


def align_up(value, align):
    """Round value to the next multiple of align."""
    return (value + align - 1) / align * align


def align_partition(min_start, min_length, start_alignment, end_alignment):
    """Compute partition start and end offsets based on specified constraints.

    :param min_start: Minimal start offset of partition
    :param min_lengh: Minimal length of partition
    :param start_alignment: Alignment of this partition
    :param end_alignment: Alignment of the data following this partition
    :return: start offset, end offset (inclusive), length
    """
    start = align_up(min_start, start_alignment)
    # end offset is inclusive, so substact one
    end = align_up(start + min_length, end_alignment) - 1
    # and add one to length
    length = end - start + 1
    return start, end, length


def prepareTable(t, disk, ram):
    # add tolerancy
    disk = disk - disk * .05
    # calculate absolute values
    need_size = 0
    rest_item = None
    for (k, v) in t.iteritems():
        size = v.get('size')
        if not size:
            error("Invalid configuration section '%s'. Has no 'size'" % k)
            sys.exit(1)
            continue
        if size.isdigit():
            need_size += long(size)
            continue
        if size == 'ram':
            v['size'] = str(ram)
            need_size += ram
            continue
        if size == 'rest':
            rest_item = v
            continue
    free_size = disk - need_size
    for (k, v) in t.iteritems():
        size = v.get('size')
        if not size:
            continue
        if isinstance(size, int):
            continue
        if isinstance(size, long):
            continue
        if isinstance(size, float):
            continue
        if size.find('%') > 0:
            percent = size.split('%')[0]
            try:
                relsize = free_size * int(percent) / 100
                v['size'] = "%d" % relsize
                need_size += relsize
            except:
                error("No valid percentage size='%s%%' in section '%s'." % (percent, k))
                sys.exit(1)
            continue
    rest = disk - need_size
    if rest < 0:
        error("Disk is to small for configuration!")
        sys.exit(1)
    rest_item['size'] = "%d" % rest

    # align partitions to allocation units

    # can only start on sector 1 (sector 0 is MBR / partition table)
    nextstart = 1
    for (k, v) in t.iteritems():
        minsize = align_up(long(v["size"]) * 1024 * 1024, SECTOR_SIZE) / SECTOR_SIZE
        minalign = PART_ALIGN_S
        (start, end, len) = align_partition(nextstart,
                                            minsize,
                                            minalign,
                                            PART_ALIGN_S)
        v["alignedsectors"] = str(minsize)
        v["start"] = str(start)
        v["end"] = str(end)
        v["len"] = str(len)
        nextstart = end + 1


def mountAll(table, root, unmount=False):
    if unmount:
        debug("Unmounting all")
    else:
        debug("Mounting all")
    items = table.items()
    items.sort(reverse=unmount)
    ret = True
    for (k, v) in items:
        if v.get('isSwap'):
            continue
        mp = v.get('mp')
        mp = "%s/%s" % (root, mp)
        dev = v.get('dev')
        if unmount:
            debug("Unmounting '%s'" % mp)
            r = run("umount %s" % mp)
            if r.returncode != 0:
                ret = False
            continue
        debug("Mounting '%s'" % mp)
        run("mkdir -p %s" % mp)
        r = run("mount %s %s" % (dev, mp))
        if r.returncode != 0:
            ret = False
    return ret


def create_hostname():
    rnd = "".join(random.sample(HOST_CHARS, HOST_LEN - 5))
    return "host-%s" % rnd


def clean_rpm_db(root):
    """Rebuild the RPM database, to prevent corruptions."""
    run('db_recover -evh %s/var/lib/rpm/' % root)


def syncVarEfw(root):
    """Syncronize /usr/lib/efw_backup/ to /var/efw/ ."""
    args = RSYNC_VAR_EFW_CMD_OPTS % root
    run('%s %s' % (RSYNC_VAR_EFW_CMD, args))


def createDirectories(root):
    debug("Create /var directory structure in '%s'" % root)
    run("mkdir %s/var/lib/" % root)
    run("ln -s /usr/share/rpm %s/var/lib/" % root)

    # clean_rpm_db(root)
    ts = rpm.TransactionSet()
    mi = ts.dbMatch()

    dirs = {}

    os.umask(0000)

    for pkg in mi:
        files = pkg[rpm.RPMTAG_FILENAMES]
        modes = pkg[rpm.RPMTAG_FILEMODES]
        users = pkg[rpm.RPMTAG_FILEUSERNAME]
        groups = pkg[rpm.RPMTAG_FILEGROUPNAME]

        for i in range(len(files)):
            fname = files[i]
            if not fname.startswith('/var'):
                continue
            mode = modes[i]
            if not stat.S_ISDIR(mode):
                # we create only directories, /var is not for packaged FILES!
                continue
            if fname == '/var':
                continue

            item = {
                'fname': fname,
                'mode': mode,
                'user': users[i],
                'group': groups[i],
                'perm': stat.S_IMODE(mode),
                'strperm': oct(stat.S_IMODE(mode)),
            }
            dirs[fname] = item

    list = dirs.items()
    list.sort()

    for (k, v) in list:
        v['fname'] = "%s%s" % (
            root,
            v['fname']
        )
        debug("%(fname)s\t\t%(user)s:%(group)s\t%(strperm)s" % (v))
        uid = 0
        gid = 0
        try:
            uid = getpwnam(v['user'])[2]
        except:
            error("%(fname)s: User '%(user)s' does not exist! Use user root" % v)
        try:
            gid = getgrnam(v['group'])[2]
        except:
            error("%(fname)s: Group '%(group)s' does not exist! Use group root" % v)
        try:
            os.makedirs(v['fname'], mode=v['perm'])
            os.chown(v['fname'], uid, gid)
        except:
            error("Could not create '%(fname)s' with perm '%(strperm)s'" % v)

    debug("Create host/settings")
    s = SettingsFile('host/settings')
    s['HOSTNAME'] = create_hostname()
    s['DOMAINNAME'] = 'localdomain'
    s.write('%s/var/efw/host/settings' % root)


def runHooks(options):
    debug("Start hooks")
    debugstr = ""
    if options.debug:
        debugstr = " --verbose"
    r = run("run-parts --report %s %s" % (debugstr, options.postHookDir))
    if r.returncode != 0:
        return False
    debug("End hooks")
    return True


def main():
    (o, a) = opthandler()
    dev = a[0]
    configureLogger(o)
    part_table = {}
    if not o.noFormat:
        part_table = readConfig(o)
        ram_size = getRam()
        disk_size = getDiskSize(dev)
        if disk_size <= 0:
            error("Size '%s' of device '%s' is to small" % (disk_size, dev))
            sys.exit(1)
        prepareTable(part_table, disk_size, ram_size)

        debug("Calculated partition table is")
        debug(part_table)

        if not createPartition(dev, part_table, disk_size):
            error("Could not create partitions on device '%s'", dev)
            sys.exit(1)
        calcDevices(dev, part_table)
        run("udevadm settle")
        if not createFs(dev, part_table):
            error("Could not create filesystems on device '%s'", dev)
            sys.exit(1)
        if not mountAll(part_table, o.root):
            error("Could not mount all partitions of device '%s'", dev)
            sys.exit(1)

    if not o.noDir:
        createDirectories(o.root)

    if os.path.isfile(RSYNC_VAR_EFW_CMD) and not o.noSync:
        syncVarEfw(o.root)

    if not o.noFormat:
        mountAll(part_table, o.root, unmount=True)

    if not o.noHooks:
        # prepare for hooks
        mountAll(part_table, '')

        if not runHooks(o):
            error("Could not run post hooks after creating /var "
                  "structure on '%s'", dev)
            sys.exit(1)

    if o.umount:
        mountAll(part_table, '', unmount=True)

if __name__ == '__main__':
    main()
