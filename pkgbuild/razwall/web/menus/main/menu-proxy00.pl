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

my %subproxyhash = ();
my $subproxy = \%subproxyhash;

$subproxy->{'01.config'} = {
    'caption' => _('Configuration'),
    'uri' => '/cgi-bin/proxyconfig.cgi',
    'title' => _('HTTP proxy: Configuration'),
    'enabled' => 1,
    'helpuri' => 'proxy.html#the-proxy-menu',
};
$subproxy->{'02.policy'} = {
    'caption' => _('Access Policy'),
    'uri' => '/cgi-bin/proxypolicy.cgi',
    'title' => _('HTTP proxy: Policy'),
    'enabled' => 1,
    'helpuri' => 'proxy/http.html#access-policy',
};
$subproxy->{'03.authentication'} = {
    'caption' => _('Authentication'),
    'uri' => '/cgi-bin/proxyauth.cgi',
    'title' => _('HTTP proxy: Authentication'),
    'enabled' => 1,
    'helpuri' => 'proxy/http.html#authentication',
};
$subproxy->{'04.authentication'} = {
    'caption' => _('NCSA user'),
    'uri' => '/cgi-bin/proxygroup.cgi',
    'title' => _('HTTP proxy: Authentication'),
    'enabled' => 0,
    'helpuri' => 'proxy/http.html#authentication',
};
$subproxy->{'05.authentication'} = {
    'caption' => _('NCSA group'),
    'uri' => '/cgi-bin/proxyuser.cgi',
    'title' => _('HTTP proxy: Authentication'),
    'enabled' => 0,
    'helpuri' => 'proxy/http.html#authentication',
};
$subproxy->{'08.virus'} = {
    'caption' => _('Antivirus'),
    'uri' => '/cgi-bin/httpantivirus.cgi',
    'title' => _('HTTP proxy: Antivirus'),
    'enabled' => 1,
    'helpuri' => 'proxy/http.html#antivirus',
};
$subproxy->{'09.adjoin'} = {
    'caption' => _('AD join'),
    'uri' => '/manage/proxy/adjoin',
    'title' => _('HTTP proxy: AD join'),
    'enabled' => 1,
    'helpuri' => 'proxy/http.html#ad-join',
};

$subproxy->{'10.https'} = {
    'caption' => _('HTTPS Proxy'),
    'uri' => '/manage/proxy/https',
    'title' => _('HTTP proxy: HTTPS Proxy'),
    'enabled' => 1,
    'helpuri' => 'proxy/http.html#https-proxy',
};

$item = {
    'caption' => _('HTTP'),
    'enabled' => 1,
    'subMenu' => $subproxy
};

register_menuitem('06.proxy', '01.http', $item);

#Status
my $item = {
    'caption' => _('Proxy graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=proxy',
    'title' => _('Proxy access graphs'),
    'enabled' => 1,
    'helpuri' => 'status.html#proxy-graphs',
};

register_menuitem('02.status', '05.proxygraphs', $item);

#reports

my %subproxylogshash = ();
my $subproxylogs = \%subproxylogshash;

$subproxylogs->{'01.proxy'} = {
    'caption' => _('HTTP'),
    'uri' => '/cgi-bin/logs_proxy.cgi',
    'title' => _('HTTP proxy log viewer'),
    'enabled' => 1,
    'helpuri' => 'logs.html#proxy',
};

if (-e '/home/httpd/menus/main/menu-proxy02-commtouch-webfilter.pl') {
$subproxylogs->{'02.contentfilter'} = {
    'caption' => _('Content filter'),
    'uri' => '/cgi-bin/logs_commtouchweb.cgi',
    'title' => _('HTTP content filter'),
    'enabled' => 1,
    'helpuri' => 'logs.html#http-and-content-filter',
};

} else {
$subproxylogs->{'02.contentfilter'} = {
    'caption' => _('Content filter'),
    'uri' => '/cgi-bin/logs_dansguardian.cgi',
    'title' => _('HTTP content filter'),
    'enabled' => 1,
    'helpuri' => 'logs.html#http-report',
};
}
$subproxylogs->{'03.sarg'} = {
    'caption' => _('HTTP report'),
    'enabled' => 1,
    'uri' => '/cgi-bin/sarg.cgi',
    'title' => _('Proxy analysis report'),
    'helpuri' => 'logs.html#http-report',
};
$subproxylogs->{'04.smtplog'} = {
    'caption' => _('SMTP'),
    'uri' => '/cgi-bin/logs_smtp.cgi',
    'title' => _('SMTP log viewer'),
    'enabled' => 1,
    'helpuri' => 'logs.html#smtp',
};

$item = {
    'caption' => _('Proxy'),
    'enabled' => 1,
    'subMenu' => $subproxylogs
};

register_menuitem('99.logs', '04.proxy', $item);

1;
