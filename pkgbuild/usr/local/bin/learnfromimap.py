#!/usr/bin/env python
# -*- coding: utf-8 -*-
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2004-2021 Endian Srl <info@endian.com>                     |
# |         Endian Srl                                                       |
# |         via Ipazia 2                                                     |
# |         39100 Bolzano (BZ)                                               |
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

import imaplib
import logging
import logging.handlers
import signal
import socket
import sys
from os import getpid, kill, path, system, unlink
from popen2 import Popen4

PID = "/run/learnfromimap.pid"

pid = getpid()

SALEARN = "sa-learn --dbpath /var/lib/spamassassin -u amavis"


class SAException(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class CvsPException(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class MyLogger:
    __log = None
    __syslog = None

    def __init__(self):
        if MyLogger.__log is None:
            self.initlog()
            MyLogger.__log = self.log
            MyLogger.__syslog = self._syslog
        else:
            self.log = MyLogger.__log
            self._syslog = MyLogger.__syslog

    def shutdown(self):
        pass

    def initlog(self):
        self.log = logging.getLogger("sa-learnIMAP")

        console = logging.StreamHandler()
        console.setLevel(logging.DEBUG)
        formatter = logging.Formatter(
            "%(name)-12s: %(levelname)-8s %(message)s"
        )
        console.setFormatter(formatter)
        self._syslog = logging.handlers.SysLogHandler(
            "/dev/log", logging.handlers.SysLogHandler.LOG_MAIL
        )
        self._syslog.setLevel(logging.INFO)
        formatter2 = logging.Formatter(
            "%(name)-12s[%(process)d]: %(levelname)-8s %(message)s"
        )
        self._syslog.setFormatter(formatter2)

        self.log.addHandler(console)
        self.log.addHandler(self._syslog)

    def set_loglevel(self, num):
        self.debuglevel = num
        level = logging.INFO - num * 10
        if level <= 0:
            level = logging.DEBUG
            # always log info and higher
        self._syslog.setLevel(level)
        self.log.setLevel(level)

    def info(self, text):
        self.log.info(text)

    def debug(self, text):
        self.log.debug(text)

    def warning(self, text):
        self.log.warning(text)

    def error(self, text):
        self.log.error(text)


class SaLearn:
    def __init__(
        self,
        host=None,
        user=None,
        password=None,
        ham="",
        spam="spam",
        delete=False,
        secure=False,
        set_debug=0,
    ):
        self.user = user
        self.password = password
        self.ham = ham
        self.spam = spam
        self.host = host
        self.delete = delete
        self.secure = secure

        self.log = MyLogger()
        self.log.set_loglevel(set_debug)

    def stop(self):
        self.log.shutdown()

    def login(self, folder):
        try:
            self.log.debug("Attempting to connect to '%s'" % (self.host))
            try:
                if ":" in self.host:
                    host, port = self.host.split(":")
                    if port == "993":
                        self.secure = True
                else:
                    host, port = self.host, ""
                if self.secure:
                    if not port:
                        port = 993
                    self._imap = imaplib.IMAP4_SSL(host, port)
                else:
                    if not port:
                        port = 143
                    self._imap = imaplib.IMAP4(host, port)
            except:
                raise SAException("Connection attempt failed.")
            self._imap.debug = self.log.debuglevel
            self.log.debug("Login with user %s" % self.user)
            self._imap.login(self.user, self.password)
        except socket.error, (errno, errstr):
            raise SAException(
                "Could not connect to %s because of '%s'."
                % (self.host, errstr)
            )
        except imaplib.IMAP4.error:
            raise SAException(
                "Login with user %s on host %s failed!"
                % (self.user, self.host)
            )
        self.log.debug("Selecting folder %s" % folder)
        errcode, data = self._imap.select(folder)
        if errcode != "OK":
            raise SAException(
                "Could not select folder %s on IMAP server %s because of '%s'."
                % (folder, self.host, data[0])
            )
        self.log.info(
            "Logged in on '%s' with user '%s' and opened folder '%s' which has '%s' mails."
            % (self.host, self.user, folder, data[0])
        )
        return data[0]

    def learn(self):
        system("%s --sync" % (SALEARN))
        self.log.info("Synched Bayes journal to database")
        if self.ham is not None:
            self.learnham()
        if self.spam is not None:
            self.learnspam()
        self.log.debug("Sync bayes db")
        system("%s --sync" % (SALEARN))
        system("chown amavis.amavis /var/lib/spamassassin/bayes_*")
        self.log.info("Synched Bayes journal to database")

    def learnham(self):
        self.log.debug("Learn ham")
        amount = self.login(self.ham)
        self.log.debug(
            "Learning ham: %s mails in folder %s" % (amount, self.ham)
        )
        self._iterate(False)
        self.close()

    def learnspam(self):
        self.log.debug("Learn spam")
        amount = self.login(self.spam)
        self.log.debug(
            "Learning spam: %s mails in folder %s" % (amount, self.spam)
        )
        self._iterate(True)
        self.close()

    def checkfolder(self):
        self.log.debug("Checking for IMAP folders")
        ret = ""
        if self.ham is not None:
            hamcount = self.login(self.ham)
            ret += "Ham mails: %s " % hamcount
            self.close()
        if self.spam is not None:
            spamcount = self.login(self.spam)
            ret += "Spam mails: %s " % spamcount
            self.close()
        self.log.info("Folder check: %s" % ret)
        return ret

    def close(self):
        self.log.debug("Expunge")
        self._imap.expunge()
        self.log.debug("Log out")
        self._imap.logout()

    def _iterate(self, spam):
        if spam:
            opt = "--spam"
        else:
            opt = "--ham"

        debugopt = ""
        verbopt = ""
        if self.log.debuglevel >= 2:
            verbopt = "--showdots"
        if self.log.debuglevel >= 3:
            debugopt = "-D"
        self.log.debug("Searching for Mails...")
        typ, data = self._imap.search(None, "ALL")

        if typ != "OK":
            raise SAException(
                "Could not find a message on IMAP server %s because of '%s'."
                % (self.host, data[0])
            )

        if len(data) == 1 and data[0] == "":
            return

        totalmails = len(data[0].split())
        self.log.debug("Found %s Mails." % totalmails)

        count = 0
        self.log.info("Processing...")
        for msg in data[0].split():
            count = count + 1
            self.log.debug("[%s: %s/%s]" % (msg, count, totalmails))
            if count % 20 == 0:
                self.log.info(
                    "Processing Mail %s of %s..." % (count, totalmails)
                )

            typ, data = self._imap.fetch(msg, "RFC822")
            if typ != "OK":
                self.log.error(
                    "Could not retrieve Message %s, because of '%s'."
                    % (msg, data[0])
                )
            try:
                mail = data[0][1]
            except Exception as errstr:
                self.log.warning(
                    "Could not retrieve e-mail information from Message %s because of '%s'!"
                    % (msg, errstr)
                )
                continue
            try:
                cmd = "%s --no-sync %s %s %s" % (
                    SALEARN,
                    opt,
                    debugopt,
                    verbopt,
                )
                self.log.debug("Call '%s' for message %s." % (cmd, msg))
                p = Popen4(cmd)
                p.tochild.write(mail)
                p.tochild.close()
                lines = p.fromchild.readlines()
                p.fromchild.close()
                ret = p.wait()
                self.log.debug("%s" % lines[0].strip())
                if ret != 0:
                    self.log.warning("Could not learn message %s!" % msg)
                    continue
            except Exception as errstr:
                self.log.warning(
                    "Could not learn message %s because of '%s'!"
                    % (msg, errstr)
                )

            if self.delete:
                self.log.debug("Delete message '%s'." % msg)
                self._imap.store(msg, "+FLAGS", "\\Deleted")


class CvsProcessor:
    def __init__(
        self,
        filename=None,
        default_host=None,
        default_user=None,
        default_password=None,
        default_ham=None,
        default_spam=None,
        secure=False,
        set_debug=0,
    ):
        self.log = MyLogger()
        self.set_debug = set_debug
        self.log.set_loglevel(self.set_debug)
        self.filename = filename

        self.default_host = default_host
        self.default_user = default_user
        self.default_password = default_password
        self.default_ham = default_ham
        self.default_spam = default_spam
        self.secure = secure

        if not path.exists(self.filename):
            raise CvsPException(
                "Could not find csv file '%s'!" % self.filename
            )

    def learn(self, test=False):
        import csv

        if test:
            self.log.info("Start connection tests")

        reader = csv.reader(open(self.filename, "r"))
        i = 0
        for row in reader:
            i = i + 1
            try:
                enabled = row[0]
                if enabled != "on":
                    continue
                host = row[1]
                user = row[2]
                password = row[3]
                ham = row[4]
                spam = row[5]
                delete = False
                if row[6] != "":
                    delete = True
            except Exception, e:
                self.log.warning(
                    "{%s} Format of line %s is invalid (%s)." % (i, i, e)
                )
                continue

            if host == "":
                host = self.default_host
            if user == "":
                user = self.default_user
            if password == "":
                password = self.default_password
            if ham == "":
                ham = self.default_ham
            if spam == "":
                spam = self.default_spam

            try:
                learn = SaLearn(
                    host,
                    user,
                    password,
                    ham,
                    spam,
                    delete,
                    self.secure,
                    self.set_debug,
                )
                learn.checkfolder()
                if not test:
                    learn.learn()
                    learn.stop()
                if test:
                    self.log.info("{%s} %s@%s: TEST OK" % (i, user, host))
            except SAException, errstr:
                self.log.error("{%s} %s@%s: %s" % (i, user, host, errstr))


def usage():
    print """
USAGE: learnfromimap.py [--debug] [--test]
                        [--host='host.name<:port>'] [--username='user'] [--password='password']
                        [--ham='ham folder'] [--spam='spam folder'] [--csv=file ]
                        [--remove] [--secure]

  debug:       be more verbose
  test:        test connections
  host:        connect to host / default hostname for --csv entries
  username:    log in with username / default username for --csv entries
  password:    log in with password / default password for --csv entries
  ham:         download ham mails from folder / default ham folder for --csv entries
  spam:        download spam mails from folder / default spam folder for --csv entries
  csv:         read out configuration information from csv file
  remove:      remove trained mails from imap
  secure:      attempt secure connection

  example:     learnfromimap.py --host='mail.domain.com:993' --username='train@domain.com' --password='secret' --ham='ham' --spam='spam'
    """
    sys.exit(1)


def processimap(
    host, user, password, ham, spam, set_debug, test, delete, secure
):
    learn = SaLearn(host, user, password, ham, spam, delete, secure, set_debug)
    learn.checkfolder()
    if not test:
        learn.learn()
    learn.stop()


def main():
    import getopt

    log = MyLogger()
    try:
        opts, args = getopt.getopt(
            sys.argv[1:],
            "dh:s:c:o:u:p:t:r:S",
            [
                "debug",
                "ham=",
                "spam=",
                "csv=",
                "host=",
                "username=",
                "password=",
                "test",
                "remove",
                "secure",
            ],
        )
    except getopt.GetoptError:
        log.error("Invalid options")
        usage()

    ham = None
    spam = None
    csvfile = None
    host = None
    user = None
    password = None
    test = False
    delete = False
    secure = False

    set_debug = 0
    for o, a in opts:
        if o in ("-d", "--debug"):
            set_debug += 1
        if o in ("-h", "--ham"):
            ham = a
        if o in ("-s", "--spam"):
            spam = a
        if o in ("-c", "--csv"):
            csvfile = a
        if o in ("-o", "--host"):
            host = a
        if o in ("-u", "--username"):
            user = a
        if o in ("-p", "--password"):
            password = a
        if o in ("-t", "--test"):
            test = True
        if o in ("-r", "--remove"):
            delete = True
        if o in ("-S", "--secure"):
            secure = True

    if csvfile is not None:
        try:
            if test:
                CvsProcessor(
                    csvfile, host, user, password, ham, spam, secure, set_debug
                ).learn(True)
            else:
                CvsProcessor(
                    csvfile, host, user, password, ham, spam, secure, set_debug
                ).learn()
        except CvsPException, strerr:
            log.error(strerr)
            sys.exit(1)
        sys.exit(0)

    if ham is None and spam is None:
        log.error("Need at least one, spam or ham folder")
        usage()

    if host is None or user is None or password is None:
        log.error("Need IMAP connection information")
        usage()

    try:
        processimap(
            host, user, password, ham, spam, set_debug, test, delete, secure
        )
        if test:
            log.info("%s@%s: TEST OK" % (user, host))
    except SAException, strerr:
        log.error("%s@%s: %s" % (user, host, strerr))
    sys.exit(1)


def writepid():
    pidfile = open(PID, "w")
    pidfile.write(str(getpid()))
    pidfile.close()


def removepid():
    if path.exists(PID):
        unlink(PID)


def handler(signum, frame):
    removepid()
    signal.signal(signum, signal.SIG_DFL)
    kill(pid, signum)


def installhandler():
    signal.signal(signal.SIGQUIT, handler)
    signal.signal(signal.SIGTERM, handler)
    signal.signal(signal.SIGINT, handler)


if __name__ == "__main__":
    installhandler()
    writepid()
    main()
    removepid()
    sys.exit(0)
