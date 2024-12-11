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
my $conffile = "${swroot}/spamassassin/settings";
my $whitelist_file = "${swroot}/spamassassin/whitelist";
my $blacklist_file = "${swroot}/spamassassin/blacklist";
my $restart     = '/usr/local/bin/restartspamassassin';
my $name        = _('Mail scanner');
my %checked     = ( 0 => '', 1 => 'checked' );

sub filter($) {
    my $str = shift;
    $str = cleanhtml($str);
    $str =~ s/|//g;
    return $str;
}


# -------------------------------------------------------------
# get settings and CGI parameters
# -------------------------------------------------------------

my %conf_hash;
my $conf = \%conf_hash;
readhash($conffile, $conf);

my $whitelist = `cat $whitelist_file 2>/dev/null`;
my $blacklist = `cat $blacklist_file 2>/dev/null`;

my %par;
getcgihash(\%par);

$par{SUBJECT_TAG} = filter($par{SUBJECT_TAG});
if ($par{SUBJECT_TAG} eq '') {
  $par{SUBJECT_TAG} = '[SPAM]';
}
if ($par{REQUIRED_HITS} !~ /^[\d\.]+$/) {
  $par{REQUIRED_HITS} = 5;
} elsif ($par{REQUIRED_HITS} < 0) {
  $par{REQUIRED_HITS} = 0;
} elsif ($par{REQUIRED_HITS} > 20) {
  $par{REQUIRED_HITS} = 20;
}

# -------------------------------------------------------------
# action to do?
# -------------------------------------------------------------

if ($par{ACTION} eq 'save') {

    my $logid = "$0 [" . scalar(localtime) . "]";
    my $needrestart = 0;

    my $checkspam = 0;
    if ( ($conf{REQUIRED_HITS} != $par{REQUIRED_HITS}) or
	 ($whitelist ne $par{WHITELIST}) or
	 ($blacklist ne $par{BLACKLIST}) or
	 ($conf{ENABLE_PYZOR} ne $par{ENABLE_PYZOR}) or
	 ($conf{ENABLE_JAPANIZATION} ne $par{ENABLE_JAPANIZATION}) or
   ($conf{ENABLE_BODY_SUMMARY} ne $par{ENABLE_BODY_SUMMARY}) or
         ($conf{SUBJECT_TAG} ne $par{SUBJECT_TAG})
       ) {
        print STDERR "$logid: writing new configuration file\n";
        $needrestart = 1;
        $conf->{REQUIRED_HITS} = $par{REQUIRED_HITS};
        $conf->{SUBJECT_TAG}   = $par{SUBJECT_TAG};
        $conf->{ENABLE_BODY_SUMMARY} = $par{ENABLE_BODY_SUMMARY};
        $conf->{ENABLE_PYZOR}   = $par{ENABLE_PYZOR};
        $conf->{ENABLE_JAPANIZATION}   = $par{ENABLE_JAPANIZATION};
	$whitelist = $par{WHITELIST};
	$blacklist = $par{BLACKLIST};

	writehash($conffile, $conf);

        open (OUT, ">$whitelist_file");
        print OUT $whitelist;
        close OUT;
        open (OUT, ">$blacklist_file");
        print OUT $blacklist;
        close OUT;
    }

    if ($needrestart) {
        print STDERR `$restart`; 
        print STDERR "$logid: restarting done\n";
    }

}

# -------------------------------------------------------------
# ouput page
# -------------------------------------------------------------

showhttpheaders();

if (!defined($conf)) {
  $errormessage = "Cannot read configuration!";
}

openpage($name, 1, '');
openbigbox($errormessage, $warnmessage, $notemessage);
openbox('100%', 'left', "$name (spamassassin)");


printf <<EOF
<form method='post' enctype='multipart/form-data' action='$ENV{SCRIPT_NAME}'>
<table border='0' cellspacing="0" cellpadding="4">
<tr valign='top'>
  <td class='base' width="40%">%s:</td>
  <td class='base'><input type='text' name='SUBJECT_TAG' value="$conf->{SUBJECT_TAG}"/></td>
</tr>

<tr valign='top'>
  <td class='base'>
     %s:
  </td>
  <td class='base'><input type='checkbox' name='ENABLE_BODY_SUMMARY' $checked{$conf->{'ENABLE_BODY_SUMMARY'}} value='1'/></td>
</tr>

<tr valign='top'>
  <td class='base'>
     %s:<br/>
     <font color="#666666" size="-4">%s</font>
  </td>
  <td class='base'><input type='text' name='REQUIRED_HITS' value='$conf->{REQUIRED_HITS}' size='2'/></td>
</tr>

<tr valign='top'>
  <td class='base'>
     %s:
  </td>
  <td class='base'><input type='checkbox' name='ENABLE_JAPANIZATION' $checked{$conf->{'ENABLE_JAPANIZATION'}} value='1'/></td>
</tr valign='top'>

<tr valign='top'>
  <td class='base'>
     %s:<br/>
     <b>%s</b>:<font color="#666666" size="-4">%s</font>
  </td>
  <td class='base'><input type='checkbox' name='ENABLE_PYZOR' $checked{$conf->{'ENABLE_PYZOR'}} value='1'/></td>
</tr>

</tr valign='top'>
<tr valign='top'>
  <td colspan="2">&nbsp;</td>
</tr>
<tr valign='top'>
  <td colspan="2" class='base'>%s</td>
</tr>
<tr valign='top'>
  <td colspan="2" class='base'>
    <textarea cols='60' rows="10" name="WHITELIST">$whitelist</textarea>
  </td>
</tr>
<tr valign='top'>
  <td colspan="2">&nbsp;</td>
</tr>
<tr valign='top'>
  <td colspan="2" class='base'>%s</td>
</tr>
<tr valign='top'>
  <td colspan="2" class='base'>
    <textarea cols='60' rows="10" name="BLACKLIST">$blacklist</textarea>
  </td>
</tr>
<tr valign='top'>
  <td class='base'><br/></td>
  <td><br/></td>
</tr>
<tr valign='top'>
  <td colspan="2">
  <input class='submitbutton' type='submit' name='submit' value='%s' /></td>
  <input type='hidden' name='ACTION' value='save' /></td>
</tr>
</table>
</form>
EOF
,
_('Spam subject tag'),
_('Add spam report to mail body'),
_('Required hits'),
_('(default value: 6)'),
_("Activate support for Japanese emails"),
_('Enable message digest spam detection (pyzor)'),
_('Note'),
_('Enabling this may dramatically slow down the POP3 proxy.'),
_('White list (valid: example@domain.com and *@example.com)'),
_('Black list (valid: example@domain.com and *@example.com)'),
_('Save')
;

closebox();
closebigbox();
closepage();

