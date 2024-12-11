#!/usr/bin/perl
#
# P3Scan CGI for Endian Firewall
#

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


# -------------------------------------------------------------
# some definitions
# -------------------------------------------------------------

require 'header.pl';
my $conffile    = "${swroot}/p3scan/settings";
my $restart     = '/usr/local/bin/restartpopscan';
my $name        = _('email scanner (POP3)');
my %checked     = ( 0 => '', 1 => 'checked', 'off' => '', 'on' => 'checked');
my %neg_checked     = ( 0 => 'checked', 1 => '', 'off' => 'checked', 'on' => '');

# -------------------------------------------------------------
# get settings and CGI parameters
# -------------------------------------------------------------

my %confhash = ();
my $conf = \%confhash;

readhash($conffile, $conf);

my %par;
getcgihash(\%par);

# -------------------------------------------------------------
# action to do?
# -------------------------------------------------------------

my $justdelete = $par{JUSTDELETE};

if ($par{ACTION} eq 'save') {

    my $logid = "$0 [" . scalar(localtime) . "]";
    my $needrestart = 0;

    if ($conf->{JUSTDELETE} != $justdelete) {
	    $conf->{JUSTDELETE} = $justdelete;
        $needrestart = 1;
    }

    if (($par{CHECKSPAM} eq 'on' ? 'on' : 'off') ne $conf->{'CHECKSPAM'}) {
        $conf->{'CHECKSPAM'} = $par{'CHECKSPAM'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    if (($par{CHECKVIRUS} eq 'on' ? 'on' : 'off') ne $conf->{'CHECKVIRUS'}) {
        $conf->{'CHECKVIRUS'} = $par{'CHECKVIRUS'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    if (($par{INTERCEPT_TLS} eq 'on' ? 'off' : 'on') ne $conf->{'IGNORE_TLS'}) {
        $conf->{'IGNORE_TLS'} = $par{'INTERCEPT_TLS'} eq 'on' ? 'off' : 'on';
        $needrestart = 1;
    }
    if (($par{LOG_FIREWALL} eq 'on' ? 'on' : 'off') ne $conf->{'LOG_FIREWALL'}) {
        $conf->{'LOG_FIREWALL'} = $par{'LOG_FIREWALL'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    if (($par{'P3SCAN_GREEN_ENABLE'} eq 'on' ? 'on' : 'off') ne $conf->{'P3SCAN_GREEN_ENABLE'}) {
        $conf->{'P3SCAN_GREEN_ENABLE'} = $par{'P3SCAN_GREEN_ENABLE'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    if (($par{'P3SCAN_BLUE_ENABLE'} eq 'on' ? 'on' : 'off') ne $conf->{'P3SCAN_BLUE_ENABLE'}) {
        $conf->{'P3SCAN_BLUE_ENABLE'} = $par{'P3SCAN_BLUE_ENABLE'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    if (($par{'P3SCAN_ORANGE_ENABLE'} eq 'on' ? 'on' : 'off') ne $conf->{'P3SCAN_ORANGE_ENABLE'}) {
        $conf->{'P3SCAN_ORANGE_ENABLE'} = $par{'P3SCAN_ORANGE_ENABLE'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }

    if ($needrestart) {
        print STDERR "$logid: writing new configuration file\n";
        open (OUT, ">$conffile");
        print OUT "CHECKSPAM=$conf->{CHECKSPAM}\n";
        print OUT "CHECKVIRUS=$conf->{CHECKVIRUS}\n";
        print OUT "IGNORE_TLS=$conf->{IGNORE_TLS}\n";
        print OUT "JUSTDELETE=$conf->{JUSTDELETE}\n";
        print OUT "LOG_FIREWALL=$conf->{'LOG_FIREWALL'}\n";
        print OUT "P3SCAN_GREEN_ENABLE=$conf->{'P3SCAN_GREEN_ENABLE'}\n";
        print OUT "P3SCAN_BLUE_ENABLE=$conf->{'P3SCAN_BLUE_ENABLE'}\n";
        print OUT "P3SCAN_ORANGE_ENABLE=$conf->{'P3SCAN_ORANGE_ENABLE'}\n";
        close OUT;
    }


    if ($needrestart) {
        print STDERR `$restart --force`; 
        print STDERR "$logid: restarting done\n";
        $notemessage = _('Changes have been saved');
    }

}

# -------------------------------------------------------------
# ouput page
# -------------------------------------------------------------

showhttpheaders();

if (!defined($conf)) {
  $errormessage=_("Cannot read configuration!");
}


openpage($name, 1, '');
openbigbox($errormessage, $warnmessage, $notemessage);
openbox('100%', 'left', $name);

printf <<EOF
<form enctype='multipart/form-data' method='post' action='$ENV{SCRIPT_NAME}'>
  <input type='hidden' name='ACTION' value='save' />
  <input type='hidden' name='JUSTDELETE' value="$conf->{'JUSTDELETE'}"/>
<table border='0' cellspacing="0" cellpadding="4">

  <tr valign="top">
    <td class='base'>%s <font color="$colourgreen">Green</font>:</td>
    <td class="base">
      <input type='checkbox' name='P3SCAN_GREEN_ENABLE' $checked{$conf->{'P3SCAN_GREEN_ENABLE'}} value='on' />
    </td>
EOF
,
_('Enabled on')
;

if (blue_used()) {
    printf <<EOF
    <td class='base'>%s <font color="$colourblue">Blue</font>:</td>
    <td class="base">
      <input type='checkbox' name='P3SCAN_BLUE_ENABLE' $checked{$conf->{'P3SCAN_BLUE_ENABLE'}} value='on' />
    </td>
EOF
,_('Enabled on')
;
} else {
    printf <<EOF
    <td colspan="2">&nbsp;</td>
EOF
;
}
print "</tr>";

if (orange_used()) {
    printf <<EOF
  <tr>
    <td class='base'>%s <font color="$colourorange">Orange</font>:</td>
    <td class="base">
      <input type='checkbox' name='P3SCAN_ORANGE_ENABLE' $checked{$conf->{'P3SCAN_ORANGE_ENABLE'}} value='on' />
    </td>
    <td colspan="2">&nbsp;</td>
  </tr>
EOF
,_('Enabled on')
;
}

    printf <<EOF
  <tr valign='top'>
    <td class='base'>%s:</td>
    <td class='base'>
      <input type='checkbox' name='CHECKVIRUS' $checked{$conf->{CHECKVIRUS}} value='on' />
    </td>
    <td class='base'>%s:</td>
    <td class='base'><input type='checkbox' name='CHECKSPAM' $checked{$conf->{CHECKSPAM}} value='on' /></td>
  </tr>
  <tr>
    <td class='base'>%s:</td>
    <td><input type='checkbox' name='INTERCEPT_TLS' $neg_checked{$conf->{'IGNORE_TLS'}} value='on' /></td>
    <td colspan="2">&nbsp;</td>
  </tr>
  <tr>
    <td class='base'>%s:</td>
    <td><input type='checkbox' name='LOG_FIREWALL' $checked{$conf->{'LOG_FIREWALL'}} value='on' /></td>
    <td colspan="2">&nbsp;</td>
  </tr>

<tr valign='top'>
  <td colspan="2">
    <input class='submitbutton' type='submit' name='submit' value='%s' />
  </td>
  <td colspan="2">&nbsp;</td>
</tr>

<tr valign='top'>
  <td colspan="4">&nbsp;</td>
</tr>

</table>
</form>
EOF
,
_('Virus scanner'),
_('Spam filter'),
_('Intercept SSL/TLS encrypted connections'),
_('Firewall logs outgoing connections'),
_('Save')
;

closebox();
closebigbox();
closepage();


