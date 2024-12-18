#!/usr/bin/perl
#
#        +-----------------------------------------------------------------------------+
#        | RazWall Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2024 RazWall                                                  |
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

require 'header.pl'; 

my %livelogsettings;
my $text = '<table class="ruleslist" width="100%" cellspacing="0">';

if (-e "/usr/lib/efw/logging/default/settings") {
  &readhash("${swroot}/logging/default/settings", \%logsettings);
}
if (-e "${swroot}/logging/settings") {
  &readhash("${swroot}/logging/settings", \%logsettings);
}
if (-e "/usr/lib/efw/logging/default/live_settings") {
  &readhash("${swroot}/logging/default/live_settings", \%livelogsettings);
}
if (-e "${swroot}/logging/live_settings") {
  &readhash("${swroot}/logging/live_settings", \%livelogsettings);
}

%logTypes = (
    'SYSTEM' => { 'color' => 'blue', 'string' => _('System'), 'default' => 'off' },
    'FIREWALL' => { 'color' => 'purple', 'string' => _('Firewall'), 'default' => 'off' },
    'HTTPD' => { 'color' => 'lightgreen', 'string' => _('Web server'), 'default' => 'off' }
);

if (-d "/usr/lib/efw/proxy/") {
    $logTypes{'SQUID'} = { 'color' => 'orange', 'string' => _('HTTP proxy'), 'default' => 'off' };
}
if (-e "/usr/lib/efw/snort/default/settings") {
    $logTypes{'SNORT'} = { 'color' => 'gray', 'string' => _('Intrusion Prevention'), 'default' => 'off' };
}
if (-d "/usr/lib/efw/openvpn/" || -d "/usr/lib/efw/openvpnclients") {
    $logTypes{'OPENVPN'} = { 'color' => 'pink', 'string' => _('OpenVPN'), 'default' => 'off' };
}
if (-d "/usr/lib/efw/clamav/") {
    $logTypes{'CLAMAV'} = { 'color' => 'darkblue', 'string' => _('%s Antivirus', "ClamAV"), 'default' => 'off' };
}
if (-e "/usr/lib/efw/panda/default/settings") {
    $logTypes{'PANDA'} = { 'color' => 'darkblue', 'string' => _('%s Antivirus', "Panda"), 'default' => 'off' };
}
if (-d "/usr/lib/efw/commtouchweb/") {
    $logTypes{'COMMTOUCHWEB'} = { 'color' => 'green', 'string' => _('Web Filter'), 'default' => 'off' };
} elsif (-d "/usr/lib/efw/dansguardian/") {
    $logTypes{'DANSGUARDIAN'} = { 'color' => 'green', 'string' => 'Web Filter', 'default' => 'off' };
}
if (-e "/usr/lib/efw/smtpscan/default/settings") {
    $logTypes{'SMTP'} = { 'color' => 'lightblue', 'string' => _('SMTP Proxy'), 'default' => 'off' };
}

&showhttpheaders();

&openpage(_('Live logs'),1,'');

print '<script type="text/javascript" language="javascript" src="/include/logs_list.js"></script>';

&openbigbox($errormessage, $warnmessage, $notemessage);
&openbox('100%','left',_('Live log viewer'));

my $i = 0;
foreach (sort keys %logTypes) {
    $text .= sprintf <<END
    <tr class="%s">
     <td class="log_type_list">%s</td>
     <td class="log_list_button"><input type="checkbox" id="%s" %s/></td>
     <td class="log_show_alone" style="text-align: right"><a href="javascript:void(0);" onclick="window.open('/cgi-bin/logs_live.cgi?show=single&showfields=%s&nosave=on','_blank','height=700,width=1000,location=no,menubar=no,scrollbars=yes');">%s</a></td>
    </tr>
END
,
    ($i % 2 == 0) ? 'even' : 'odd',
    $logTypes{$_}{'string'},
    lc($_),
    (exists($livelogsettings{'LIVE_'.$_}) && $livelogsettings{'LIVE_'.$_} eq 'on') ? "checked='checked'" : '',
    lc($_),
    _('Show this log only');
    $i++;
}

printf <<END
    %s
    <tr><td>&nbsp;</td><td class="select_all_logs"><input type="checkbox" onclick="selectAllLogs();" id="select_all" />&nbsp;%s</td><td>&nbsp;</td></tr>
    </table>
    <center><br/><button onclick="showSelectedLogs();">%s</button><center>
END
,
$text,
_('Select all'),
_('Show selected logs');


&closebox();
&closebigbox();
&closepage();
