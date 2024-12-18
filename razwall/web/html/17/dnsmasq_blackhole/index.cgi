#!/usr/bin/python

import os
import re
import csv
import urlparse
import endian.core.version
from endian.job.commons import DataSource
from endian.core import i18n

TEMPLATE_NAME = 'dnsmasq_blackhole.html'
TEMPLATES_DIR = '/usr/share/dnsmasq/templates/'
PHISHTANK_CSV = '/var/signatures/dnsmasq/phishtank.csv'

re_placeholders = re.compile(r'%\b(.+?)\b')

def get_phishtank_link():
    """Return a link where more information can be found."""
    host = os.environ.get('HTTP_HOST')
    if not host:
        return _("No information available.")
    try:
        fd = open(PHISHTANK_CSV, 'r')
        reader = csv.reader(fd)
        for entry in reader:
            try:
                entry_host = urlparse.urlparse(entry[1])[1]
                if entry_host == host:
                    fd.close()
                    return '<a href="%s">%s</a>' % (entry[2], entry[2])
            except Exception:
                continue
        fd.close()
    except Exception:
        pass
    return _("No information available.")


i18n_strings = {
    'PRODUCT': '%s %s' % (endian.core.version.get_brand(), endian.core.version.get_product()),
    'INFO_LINK': get_phishtank_link(),
    'QUERY_STRING': '%s://%s%s' % ((os.environ.get('HTTPS') and 'https' or 'http'),
        os.environ.get('SERVER_NAME', ''), os.environ.get('REQUEST_URI', ''))
}


def _replacePlaceholder(matchobj):
    """Replace matching strings."""
    matchtxt = matchobj.group(1)
    return i18n_strings.get(matchtxt, matchtxt)


def guessLang():
    """Guess the language from the browser or from our settings."""
    lang = os.environ.get('LANG') or DataSource().get('main').settings.get('LANGUAGE')
    return lang


def getTemplate(lang):
    """Return the template in the given language (or English if
    not available)."""
    template_dir = os.path.join(TEMPLATES_DIR, lang)
    if not os.path.isdir(template_dir):
        template_dir = os.path.join(TEMPLATES_DIR, 'en')
    try:
        tmpl_fd = open(os.path.join(template_dir, TEMPLATE_NAME))
        tmpl = tmpl_fd.read()
    finally:
        tmpl_fd.close()
    return tmpl


def fillTemplate(tmpl):
    """Replace placeholders in the template."""
    return re_placeholders.sub(_replacePlaceholder, tmpl)



if __name__ == '__main__':
    print "Pragma: no-cache"
    print "Cache-control: no-cache"
    print "Connection: close"
    print "Content-type: text/html"
    print ""
    lang = guessLang()
    tmpl = getTemplate(lang)
    print fillTemplate(tmpl)

