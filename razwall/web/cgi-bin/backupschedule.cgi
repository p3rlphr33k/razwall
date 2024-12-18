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

# -------------------------------------------------------------------
# Check if the demo mode is enabled

my $demo_conffile = "${swroot}/demo/settings";
my $demo_conffile_default = "/usr/lib/efw/demo/default/settings";
my %demo_settings_hash = ();
my $demo_settings = \%demo_settings_hash;

if (-e $demo_conffile_default) {
    readhash($demo_conffile_default, $demo_settings);
}

if (-e $demo_conffile) {
    readhash($demo_conffile, $demo_settings);
}

my $demo = $demo_settings->{'DEMO_ENABLED'} eq 'on';

# -------------------------------------------------------------------

my $conffile    = "${swroot}/backup/settings";
my $restart     = '/usr/local/bin/restartbackup';
my $sendmail    = '/usr/local/bin/sendautobackup';
my %checked     = ( 0 => '', 1 => 'checked', 'on' => 'checked' );
my %frequency = ('hourly' => '', 'daily' => '', 'weekly' => '', 'monthly' => '');

my $name = _('Scheduled automatic backups');
my $errormessage='';

my %confhash = ();
my $conf = \%confhash;
my %par;

my $logid = 'backupschedule.cgi';

sub setfrequency() {
    $frequency{'hourly'} = '';
    $frequency{'daily'} = '';
    $frequency{'weekly'} = '';
    $frequency{'monthly'} = '';
    $frequency{$conf->{'BACKUP_SCHEDULE'}} = 'checked="checked"';
}

sub loadconfig() {
    readhash($conffile, $conf);
    setfrequency();
}

# -------------------------------------------------------------
# action to do?
# -------------------------------------------------------------

sub save() {

    if ($par{'BACKUP_RETENTION'} !~ /^\d+$/) {
        $errormessage = _('Retention value need to be a number!');
        return;
    }
    if (($par{'BACKUP_LOGS'} !~ /on/) && ($par{'BACKUP_SETTINGS'} !~ /on/) && ($par{'BACKUP_HWDATA'} !~ /on/)) {
        $errormessage = _('Include at least something to backup!');
        return;
    }

    if ($par{'BACKUP_MAIL'} =~ /on/) {
        if ($par{'BACKUP_RCPTTO'} =~ /^$/) {
            $errormessage = _('Recipient email address is required!');
            return;
        }
        if (! validemail($par{'BACKUP_RCPTTO'})) {
            $errormessage = _('"%s" is no valid email address!', $par{'BACKUP_RCPTTO'});
            return;
        }
        if ($par{'BACKUP_MAILFROM'} !~ /^$/) {
            if (! validemail($par{'BACKUP_MAILFROM'})) {
                $errormessage = _('"%s" is no valid email address!', $par{'BACKUP_MAILFROM'});
                return;
            }
        }
        if ($par{'BACKUP_SMARTHOST'} !~ /^$/) {
            if (!validhostname($par{'BACKUP_SMARTHOST'}) && 
		!validfqdn($par{'BACKUP_SMARTHOST'}) && 
		!is_ipaddress($par{'BACKUP_SMARTHOST'})) {
                $errormessage = _('Smarthost "%s" is no valid hostname or IP address!', $par{'BACKUP_SMARTHOST'});
                return;
            }
        }
        $par{'BACKUP_LOGARCHIVES'} = 'off';

    }

    if ($demo) {
        return;
    }

    if ( ($conf->{'BACKUP_ENABLED'} ne $par{'BACKUP_ENABLED'}) or
         ($conf->{'BACKUP_SCHEDULE'} ne $par{'BACKUP_SCHEDULE'}) or
         ($conf->{'BACKUP_LOGS'} ne $par{'BACKUP_LOGS'}) or
         ($conf->{'BACKUP_LOGARCHIVES'} ne $par{'BACKUP_LOGARCHIVES'}) or
         ($conf->{'BACKUP_HWDATA'} ne $par{'BACKUP_HWDATA'}) or
         ($conf->{'BACKUP_DBDUMP'} ne $par{'BACKUP_DBDUMP'}) or
         ($conf->{'BACKUP_SETTINGS'} ne $par{'BACKUP_SETTINGS'}) or
         ($conf->{'BACKUP_RETENTION'} ne $par{'BACKUP_RETENTION'}) or
         ($conf->{'BACKUP_MAIL'} ne $par{'BACKUP_MAIL'}) or
         ($conf->{'BACKUP_RCPTTO'} ne $par{'BACKUP_RCPTTO'}) or
         ($conf->{'BACKUP_MAILFROM'} ne $par{'BACKUP_MAILFROM'}) or
         ($conf->{'BACKUP_SMARTHOST'} ne $par{'BACKUP_SMARTHOST'})
       ) {
        print STDERR "$logid: writing new configuration file\n";
        $needrestart = 1;
        $conf->{'BACKUP_ENABLED'} = $par{'BACKUP_ENABLED'};
        $conf->{'BACKUP_SCHEDULE'} = $par{'BACKUP_SCHEDULE'};
        $conf->{'BACKUP_LOGS'} = $par{'BACKUP_LOGS'};
        $conf->{'BACKUP_SETTINGS'} = $par{'BACKUP_SETTINGS'};
        $conf->{'BACKUP_LOGARCHIVES'} = $par{'BACKUP_LOGARCHIVES'};
        $conf->{'BACKUP_HWDATA'} = $par{'BACKUP_HWDATA'};
        $conf->{'BACKUP_DBDUMP'} = $par{'BACKUP_DBDUMP'};
        $conf->{'BACKUP_RETENTION'} = $par{'BACKUP_RETENTION'};
        $conf->{'BACKUP_MAIL'} = $par{'BACKUP_MAIL'};
        $conf->{'BACKUP_RCPTTO'} = $par{'BACKUP_RCPTTO'};
        $conf->{'BACKUP_MAILFROM'} = $par{'BACKUP_MAILFROM'};
        $conf->{'BACKUP_SMARTHOST'} = $par{'BACKUP_SMARTHOST'};
	setfrequency();

        writehash($conffile, $conf);
    }
    if ($needrestart) {
        system($restart); 
    }
    if ($par{'SENDNOW'} !~ /^$/) {
        system($sendmail);
    }
}

sub display() {

    printf <<EOF
<form enctype='multipart/form-data' method='post' action='$ENV{SCRIPT_NAME}'>
  <input type='hidden' name='ACTION' value='save' />
EOF
;

    openbox('100%', 'left', $name);

    printf <<END
<table columns="5">
  <tr>
    <td>%s:</td>
    <td>
      <input type='checkbox' name='BACKUP_ENABLED' value='on' $checked{$conf->{'BACKUP_ENABLED'}} />
    </td>
    <td colspan="2">%s:</td>
    <td>
      <input type='checkbox' name='BACKUP_SETTINGS' value='on' $checked{$conf->{'BACKUP_SETTINGS'}} />
    </td>
  </tr>

  <tr>
    <td>%s:</td>
    <td>
      <select name='BACKUP_RETENTION'>
END
, _('Enabled')
, _('Include configuration')
, _('Keep # of archives')
;

    my @entries = qw '2 3 4 5 6 7 8 9 10';
    foreach my $entry (@entries) {
	my $selected = '';
	if ($entry eq $conf->{'BACKUP_RETENTION'}) {
	    $selected = 'selected';
	}
	print "<option $selected value=\"$entry\">$entry</option>";
    }

    printf <<END
        </select>
    </td>
    <td colspan="2">%s:</td>
    <td>
      <input type='checkbox' name='BACKUP_DBDUMP' value='on' $checked{$conf->{'BACKUP_DBDUMP'}} />
    </td>
  </tr>

  <tr>
    <td colspan="2">&nbsp;</td>
    <td colspan="2">%s:</td>
    <td>
      <input type='checkbox' name='BACKUP_LOGS' value='on' $checked{$conf->{'BACKUP_LOGS'}} />
    </td>
  </tr>
  <tr>
    <td colspan="2">&nbsp;</td>
    <td colspan="2">%s:</td>
    <td>
      <input type='checkbox' name='BACKUP_LOGARCHIVES' value='on' $checked{$conf->{'BACKUP_LOGARCHIVES'}} />
    </td>
  </tr>
  <tr>
    <td colspan="2">&nbsp;</td>
    <td colspan="2">%s:</td>
    <td>
      <input type='checkbox' name='BACKUP_HWDATA' value='on' $checked{$conf->{'BACKUP_HWDATA'}} />
    </td>
  </tr>

</table>

<br>

<table columns="4" width="100%">
  <tr>
    <td colspan="4"><b>%s</b></td>
  </tr>

  <tr>
    <td><input type="radio" name="BACKUP_SCHEDULE" $frequency{'hourly'} value="hourly"> %s <a href="javascript:void(0);" onmouseover="return overlib('%s',STICKY, MOUSEOFF);" onmouseout="return nd();">?</a></td>
    <td><input type="radio" name="BACKUP_SCHEDULE" $frequency{'daily'} value="daily"> %s <a href="javascript:void(0);" onmouseover="return overlib('%s',STICKY, MOUSEOFF);" onmouseout="return nd();">?</a></td>
    <td><input type="radio" name="BACKUP_SCHEDULE" $frequency{'weekly'} value="weekly"> %s <a href="javascript:void(0);" onmouseover="return overlib('%s',STICKY, MOUSEOFF);" onmouseout="return nd();">?</a></td>
    <td><input type="radio" name="BACKUP_SCHEDULE" $frequency{'monthly'} value="monthly"> %s <a href="javascript:void(0);" onmouseover="return overlib('%s',STICKY, MOUSEOFF);" onmouseout="return nd();">?</a></td>
  </tr>

  <tr valign='top'>
    <td colspan="2">
      <input class='submitbutton' type='submit' name='submit' value='%s' />
    </td>
    <td colspan="2">&nbsp;</td>
  </tr>
</table>
END
, _('Include database dumps')
, _('Include log files')
, _('Include log archives')
, _('Include hardware data')
, _('Schedule for automatic backups')
, _('Hourly')
, _('Every hour one minute after the full hour. (XX:01)')
, _('Daily')
, _('Every day at 01:25 am')
, _('Weekly')
, _('Every Sunday at 02:47 am')
, _('Monthly')
, _('Every 1st day of month on 03:52 am')
, _('Save')
;

    closebox();

    openbox('100%', 'left', _('Send backups via email'));
    printf <<END
<table columns="4">
  <tr>
    <td>%s</td>
    <td>
      <input type='checkbox' name='BACKUP_MAIL' value='on' $checked{$conf->{'BACKUP_MAIL'}} />
    </td>
    <td colspan="2">&nbsp;</td>
  </tr>

  <tr>
    <td>%s *</td>
    <td><input type='text' name='BACKUP_RCPTTO' value='$conf->{'BACKUP_RCPTTO'}' /></td>
    <td>%s</td>
    <td><input type='text' name='BACKUP_MAILFROM' value='$conf->{'BACKUP_MAILFROM'}' /></td>
  </tr>
  <tr>
    <td>%s</td>
    <td colspan="3"><input type='text' name='BACKUP_SMARTHOST' value='$conf->{'BACKUP_SMARTHOST'}' /></td>
  </tr>

  <tr>
    <td colspan="4"><b>%s</b>: %s</td>
  </tr>

  <tr>
    <td colspan="4">&nbsp;</td>
  </tr>

  <tr valign='top'>
    <td>
      <input class='submitbutton' type='submit' name='SUBMIT' value='%s' />
    </td>
    <td>
      <input class='submitbutton' type='submit' name='SENDNOW' value='%s' />
    </td>
    <td colspan="2" style="text-align: right;">*&nbsp;%s</td>
  </tr>
</table>
</form>
END
, _('Enabled')
, _('email address of recipient')
, _('email address of sender')
, _('Address of smarthost to be used')
, _('Note')
, _('If mailing is enabled, log file archives will be excluded.')
, _('Save')
, _('Send a backup now')
, _('This field is required.')
;

    closebox();

}

# -------------------------------------------------------------
# ouput page
# -------------------------------------------------------------
getcgihash(\%par);
showhttpheaders();
loadconfig();

if (!defined($conf)) {
  $erromessage = _('Cannot read configuration!');
}

openpage($name, 1, '');

if ($par{'ACTION'} eq 'save') {
  save();
}
&openbigbox($errormessage, $warnmessage, $notemessage);
display();
closebigbox();
closepage();





