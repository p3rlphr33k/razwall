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
# -------------------------------------------------------------
# some definitions
# -------------------------------------------------------------

require 'header.pl';
my $conffile    = "${swroot}/frox/settings";
my $restart     = '/usr/local/bin/restartfrox';
my $name        = _('FTP virus scanner');
my %checked     = ( 0 => '', 1 => 'checked', 'off' => '', 'on' => 'checked');
my $source_bypass_file = "${swroot}/frox/source_bypass";
my $destination_bypass_file = "${swroot}/frox/destination_bypass";


# -------------------------------------------------------------
# get settings and CGI parameters
# -------------------------------------------------------------

my $transparent_source_bypass = '';
my $transparent_destination_bypass = '';
my %confhash = ();
my $conf = \%confhash;

readhash($conffile, $conf);

if (-e "$source_bypass_file") {
    open(FILE, "$source_bypass_file");
    foreach my $line (<FILE>) {
        $transparent_source_bypass .= $line;
    };
close(FILE);
}
if (-e "$destination_bypass_file") {
    open(FILE, "$destination_bypass_file");
    foreach my $line (<FILE>) {
        $transparent_destination_bypass .= $line;
    };
close(FILE);
}

my %par;
getcgihash(\%par);

# -------------------------------------------------------------
# action to do?
# -------------------------------------------------------------

sub check_acl($$) {
    my $data = shift;
    my $withMAC = shift;
    my $ret = '';
    @temp = split(/\n/,$data);
    foreach my $item (@temp) {
        $item =~ s/^\s+//g;
        $item =~ s/\s+$//g;
        next if ($item =~ /^$/);
	if (! validmac($item) && ! validipormask($item)) {
		if ($withMAC) {
			$errormessage = _('"%s" is no valid IP address, network or MAC address', $item);
		} else {
			$errormessage = _('"%s" is no valid IP address or network address', $item);
		}
            return (1, $data);
        }
        $ret .= ipmask_to_cidr($item)."\n";
    }
    return (0, $ret);
}

sub writelist($$) {
    my $file = shift;
    my $data = shift;

    open(FILE, ">$file");
    print FILE $data;
    close(FILE);
}

showhttpheaders();

if ($par{ACTION} eq 'save') {

    my $logid = "$0 [" . scalar(localtime) . "]";
    my $needrestart = 0;

	$needrestart = 1;
	
    if (($par{LOG_FIREWALL} eq 'on' ? 'on' : 'off') ne $conf->{'LOG_FIREWALL'}) {
        $conf->{'LOG_FIREWALL'} = $par{'LOG_FIREWALL'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }

    if (($par{'FROX_GREEN_ENABLE'} eq 'on' ? 'on' : 'off') ne $conf->{'FROX_GREEN_ENABLE'}) {
        $conf->{'FROX_GREEN_ENABLE'} = $par{'FROX_GREEN_ENABLE'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    if (($par{'FROX_BLUE_ENABLE'} eq 'on' ? 'on' : 'off') ne $conf->{'FROX_BLUE_ENABLE'}) {
        $conf->{'FROX_BLUE_ENABLE'} = $par{'FROX_BLUE_ENABLE'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    if (($par{'FROX_ORANGE_ENABLE'} eq 'on' ? 'on' : 'off') ne $conf->{'FROX_ORANGE_ENABLE'}) {
        $conf->{'FROX_ORANGE_ENABLE'} = $par{'FROX_ORANGE_ENABLE'} eq 'on' ? 'on' : 'off';
        $needrestart = 1;
    }
    
    if ($needrestart) {
        print STDERR "$logid: writing new configuration file\n";
        open (OUT, ">$conffile");
        print OUT "LOG_FIREWALL=$conf->{'LOG_FIREWALL'}\n";
        print OUT "FROX_GREEN_ENABLE=$conf->{'FROX_GREEN_ENABLE'}\n";
        print OUT "FROX_BLUE_ENABLE=$conf->{'FROX_BLUE_ENABLE'}\n";
        print OUT "FROX_ORANGE_ENABLE=$conf->{'FROX_ORANGE_ENABLE'}\n";
        close OUT;    
    }

    my $error = 0;
    ($error, $transparent_destination_bypass) = check_acl($par{'TRANSPARENT_DESTINATION_BYPASS'}, 0);
    ($error, $transparent_source_bypass) = check_acl($par{'TRANSPARENT_SOURCE_BYPASS'}, 1);
        
    if (! $error) {
        $transparent_source_bypass = uc($transparent_source_bypass);
        $transparent_destination_bypass = uc($transparent_destination_bypass);
        writelist($source_bypass_file, $transparent_source_bypass);
        writelist($destination_bypass_file, $transparent_destination_bypass);   
        
        # TODO:restart only if needed
        $needrestart = 1 
    }

    if (($needrestart) and (! $error)) {
        print STDERR `$restart --force`; 
        print STDERR "$logid: restarting done\n";
    }

}

# -------------------------------------------------------------
# ouput page
# -------------------------------------------------------------



if (!defined($conf)) {
  $errormessage=_("Cannot read configuration!");
} 
openpage($name, 1, '');
&openbigbox($errormessage, $warnmessage, $notemessage);
openbox('100%', 'left', "$name");

printf <<EOF
<form enctype='multipart/form-data' method='post' action='$ENV{SCRIPT_NAME}'>
<input type='hidden' name='ACTION' value='save' />
<table border='0' cellspacing="0" cellpadding="4">

  <tr valign="top">
    <td class='base'>%s <font color="$colourgreen">Green</font>:</td>
    <td class="base">
      <input type='checkbox' name='FROX_GREEN_ENABLE' $checked{$conf->{'FROX_GREEN_ENABLE'}} />
    </td>
EOF
,
_('Enabled on')
;

if (blue_used()) {
    printf <<EOF
    </tr><tr>
    <td class='base'>%s <font color="$colourblue">Blue</font>:</td>
    <td class="base">
      <input type='checkbox' name='FROX_BLUE_ENABLE' $checked{$conf->{'FROX_BLUE_ENABLE'}} />
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

if (orange_used()) {
    printf <<EOF
    </tr><tr>
    <td class='base'>%s <font color="$colourorange">Orange</font>:</td>
    <td class="base">
      <input type='checkbox' name='FROX_ORANGE_ENABLE' $checked{$conf->{'FROX_ORANGE_ENABLE'}} />
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

    printf <<EOF
  </tr>

<tr>
  <td class='base'>%s:</td>
  <td><input type='checkbox' name='LOG_FIREWALL' $checked{$conf->{'LOG_FIREWALL'}} /></td>
  <td colspan="2">&nbsp;</td>
</tr>

EOF
,
_('Firewall logs outgoing connections')
;
    printf <<EOF
  <tr valign='top'>
    <td class='base'>%s:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>%s:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    
  </tr>
  <tr valign='top'>
    <td>
      <textarea name='TRANSPARENT_SOURCE_BYPASS' cols='32' rows='6' wrap='off'>$transparent_source_bypass</textarea>
    </td>
    <td>
      <textarea name='TRANSPARENT_DESTINATION_BYPASS' cols='32' rows='6' wrap='off'>$transparent_destination_bypass</textarea>
    </td>
    <td colspan="2">&nbsp;</td>
  </tr>
  
  <tr valign='top'>
    <td colspan="4">&nbsp;</td>
  </tr>

  <tr valign='top'>
    <td colspan="2">
      <input class='submitbutton' type='submit' name='submit' value='%s' />
    </td>
    <td colspan="2">&nbsp;</td>
  </tr>

  <tr valign='top'>
    <td colspan="2">&nbsp;</td>
  </tr>

</table>
</form>
EOF
, _('Bypass the transparent Proxy from Source (one subnet/ip/mac per line)')
, _('Bypass the transparent Proxy to Destination (one subnet/ip per line)')
, _('Save')
;


closebox();
closebigbox();
closepage();

