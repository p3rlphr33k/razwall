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


my %smtpscan_settings = ();
&readhash("/var/efw/smtpscan/settings", \%smtpscan_settings);

my %subsmtphash = ();
my $subsmtp = \%subsmtphash;

if ($smtpscan_settings{'SMARTHOST_ONLY'} ne 'on') {

    $subsmtp->{'01.config'} = {
        'caption' => _('Configuration'),
        'uri' => '/cgi-bin/smtpconfig.cgi',
        'title' => _('SMTP proxy: Configuration'),
        'enabled' => 1,
        'helpuri' => 'proxy/smtp.html#configuration',
    };

    $subsmtp->{'02.lists'} = {
        'caption' => _('Black- & Whitelists'),
        'uri' => '/cgi-bin/smtplists.cgi',
        'title' => _('SMTP Black- & Whitelists'),
        'enabled' => 1,
        'helpuri' => 'proxy/smtp.html#black-whitelists',
    };

    $subsmtp->{'03.domains'} = {
        'caption' => _('Incoming domains'),
        'uri' => '/cgi-bin/smtpdomains.cgi',
        'title' => _('SMTP proxy: Incoming domains'),
        'enabled' => 1,
        'helpuri' => 'proxy/smtp.html#incoming-domains',
    };

    $subsmtp->{'04.domainrouting'} = {
        'caption' => _('Domain routing'),
        'uri' => '/manage/smtpscan/domainrouting',
        'title' => _('SMTP proxy: Domain routing'),
        'enabled' => 1,
        'helpuri' => 'proxy/smtp.html#domain-routing',
    };

    $subsmtp->{'05.routing'} = {
        'caption' => _('Mail routing'),
        'uri' => '/cgi-bin/smtprouting.cgi',
        'title' => _('SMTP proxy: Mail routing'),
        'enabled' => 1,
        'helpuri' => 'proxy/smtp.html#mail-routing',
    };

    $subsmtp->{'06.advanced'} = {
        'caption' => _('Advanced'),
        'uri' => '/manage/smtpscan/advanced',
        'title' => _('SMTP proxy: advanced'),
        'enabled' => 1,
        'helpuri' => 'proxy/smtp.html#advanced',
    };

} else {

    $subsmtp->{'06.advanced'} = {
        'caption' => _('Smarthost configuration'),
        'uri' => '/manage/smtpscan/advanced',
        'title' => _('SMTP proxy'),
        'enabled' => 1,
        'helpuri' => 'proxy/smtp.html#advanced',
    };

}

$item = {
    'caption' => _('SMTP'),
    'enabled' => 1,
    'subMenu' => $subsmtp
};

register_menuitem('06.proxy', '05.smtp', $item);

1;
