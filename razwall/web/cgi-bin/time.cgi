#!/usr/bin/perl
#
# IPCop CGIs
#
# This file is part of the IPCop Project
# 
# This code is distributed under the terms of the GPL
#
# (c) Eric Oberlander June 2002
#
# (c) Darren Critchley June 2003 - added real time clock setting, etc

require 'header.pl';

my $conffile = '/var/efw/time/settings';
#my $enabled = 0;
my %conf_hash = ();
my $conf = \%conf_hash;
my $restart = 'jobcontrol restart ntp';
my $sync = 'jobcontrol call ntp.sync';
my $update_time = 'jobcontrol call ntp.update_time --timestamp=';
my %checked     = ( 0 => '', 1 => 'checked', 'on' => 'checked');
my $mainsettings = '/var/efw/main/settings';


my %par;

sub loadconfig() {
    readhash($conffile, $conf);
    if ($conf->{'TIMEZONE'} =~ /^$/) {
        my %mainhash = ();
        my $mainconf = \%mainhash;
        readhash($mainsettings, $mainconf);
        $conf->{'TIMEZONE'} = $mainconf->{'TIMEZONE'};
        $conf->{'TIMEZONE'} =~ s+/usr/share/zoneinfo/(posix/)?++;
    }
    if (($conf->{'NTP_ADDR_1'} !~ /^$/) || ($conf->{'NTP_ADDR_2'} !~ /^$/)) {
        $conf->{'NTP_SERVER_LIST'} .= $conf->{'NTP_ADDR_1'}.",".$conf->{'NTP_ADDR_2'}.","
    }

    delete($conf->{'NTP_ADDR_1'});
    delete($conf->{'NTP_ADDR_2'});
}

sub action() {
    if ($par{'SYNCACTION'} !~ /^$/) {
        `$sync`;
        return;
    }
    if ($par{'ACTION'} eq 'update') {
        updatetime();
        return;
    }
    if ($par{'ACTION'} eq "save") {
        save();
        return;
    }
}

sub updatetime() {
    if ($par{'SETHOUR'} eq '' || $par{'SETHOUR'} < 0 || $par{'SETHOUR'} > 23) {
        $errormessage = _('Invalid time entered.');
        return;
    }
    if ($par{'SETMINUTES'} eq '' || $par{'SETMINUTES'} < 0 || $par{'SETMINUTES'} > 59) {
        $errormessage = _('Invalid time entered.');
        return;
    }
    if ($par{'SETDAY'} eq '' || $par{'SETDAY'} < 1 || $par{'SETDAY'} > 31) {
        $errormessage = _('Invalid date entered.');
        return;
    }
    if ($par{'SETMONTH'} eq '' || $par{'SETMONTH'} < 1 || $par{'SETMONTH'} > 12) {
        $errormessage = _('Invalid date entered.');
        return;
    }
    if ($par{'SETYEAR'} eq '' || $par{'SETYEAR'} < 2003 || $par{'SETYEAR'} > 2300) {
        $errormessage = _('Invalid date entered.');
        return;
    }

    system ("jobcontrol call ntp.update_time \"options(year:$par{'SETYEAR'},month:$par{'SETMONTH'},day:$par{'SETDAY'},hour:$par{'SETHOUR'},minute:$par{'SETMINUTES'})\" >/dev/null 2>&1");
    &log(_('Time/Date manually reset.')." $datestring $timestring");
    `$restart`;
}

sub save() {

    $par{'NTP_SERVER_LIST'} =~ s/\r?\n/,/g;
    foreach my $server (split(/,/, $par{'NTP_SERVER_LIST'})) {
        next if ($server =~ /^$/);
        if ( ! ( &validfqdn($server) || &validip  ($server))) {
            $errormessage = _('Invalid NTP server address "%s".', $server);
            return;
        }
    }
    if ($par{'SERVER_OVERRIDE'} eq 'on') {
        if ($par{'NTP_SERVER_LIST'} eq '') {
            $errormessage = _('Cannot override NTP servers with empty server list.');
        return;
        }
    }
    
    my $reload = 0;
    if (($par{'NTP_SERVER_LIST'} ne $conf->{'NTP_SERVER_LIST'}) ||
        ($par{'TIMEZONE'} ne $conf->{'TIMEZONE'}) ||
        ($par{'SERVER_OVERRIDE'} ne $conf->{'SERVER_OVERRIDE'})) {
        $conf->{'NTP_SERVER_LIST'} = $par{'NTP_SERVER_LIST'};
        $conf->{'SERVER_OVERRIDE'} = $par{'SERVER_OVERRIDE'};
        $conf->{'TIMEZONE'} = $par{'TIMEZONE'};
        $reload = 1;
    writehash($conffile, $conf);
        &log(_('Written down NTP configuration'));
    }

    if ($reload) {
        `$restart`;
    }
}

sub timezone_select {
    my $select_box = "<select name='TIMEZONE'>";
    use DateTime::TimeZone;
    my @zones = DateTime::TimeZone::all_names;
    push(@zones, "GMT");
    push(@zones, "UTC");
    foreach my $zone (sort @zones) {
        my $checked = '';
        if ($conf->{'TIMEZONE'} eq $zone) {
            $checked = 'selected';
        }
	$select_box .= "<option value='$zone' $checked>$zone</option>";
    }
    $select_box .= "</select>";
    return $select_box;
}

sub display() {
    my $ntp_servers = $conf->{'NTP_SERVER_LIST'};
    $ntp_servers =~ s/,/\n/g;
    
    my $show_servers = "hidden";
    
    if ($checked{$conf->{'SERVER_OVERRIDE'}}) {
        $show_servers = "";
    }
    
    &openbox('100%', 'left', _('Use a network time server'));
    
    printf <<END
    <script type="text/javascript">
        \$(document).ready(function() {
            \$('#custom-server').click(function() {
                if(\$('#custom-server').get(0).checked) 
                    \$('#server-list').show();
                else
                    \$('#server-list').hide();
            });
        });
    </script>
    
    <form method='post' class="service-switch-form" action='$ENV{'SCRIPT_NAME'}'>
    <input type='hidden' name='ACTION' value='save' />

    <table cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td valign="top">
                <div id="access-options" class="options-container efw-form">
                    <div class="section">
                        <div class="title"><h2 class="title">%s</h2></div>
                        <div class="fields-row">
                            <span class="multi-field checkbox">
                                <input type='checkbox' style="vertical-align" id="custom-server" name='SERVER_OVERRIDE' $checked{$conf->{'SERVER_OVERRIDE'}} value='on'/>
                                <label id="username_field" for="username">%s *</label></span>
                            <br class="cb" />
                        </div>
                        <div class="fields-row $show_servers" id="server-list">
                            <span class="multi-field">
                                <textarea name='NTP_SERVER_LIST' cols='20' rows='4' wrap='off'>$ntp_servers</textarea></span>
                            <br class="cb" />
                        </div>
                        <div class="fields-row">
                            <span class="multi-field">
                                <label id="username_field" for="username">%s *</label>
                                %s</span>
                            <br class="cb" />
                        </div>
                    </div>
                    <div class="save-button">
                        <input class='submitbutton save-button' type='submit' name='SUBMITACTION' value='%s' />&nbsp;%s&nbsp;
                        <input class='submitbutton save-button' type='submit' name='SYNCACTION' value='%s' />
                    </div>
                </div>
            </td>
        </tr>
    </table>
</form>
END
,
_('Settings'),
_('Override default NTP servers'),
_("Timezone"),
timezone_select(),
_('Save'),
_('or'),
_('Synchronize now')
;

    &closebox();

    use DateTime;
    my $dt = DateTime->now(time_zone=>$conf->{'TIMEZONE'});
    my $year = $dt->year;
    my $month  = $dt->month;
    my $day    = $dt->day;
    my $hour   = $dt->hour;
    my $minute = $dt->minute;

    &openbox('100%', 'left', _('Adjust manually'));

    printf <<END
<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
<input type='hidden' name='ACTION' value='update' />
<table width='100%'>
  <tr>
    <td>
        %s: <input type='text' name='SETYEAR' size='4' maxlength='4' value='$year' />
        &nbsp; %s: <input type='text' name='SETMONTH' size='2' maxlength='2' value='$month' />
        &nbsp; %s: <input type='text' name='SETDAY' size='2' maxlength='2' value='$day' />
        &nbsp; &nbsp; &nbsp;
        %s: <input type='text' name='SETHOUR' size='2' maxlength='2' value='$hour' />
        &nbsp; %s: <input type='text' name='SETMINUTES' size='2' maxlength='2' value='$minute' />
    	&nbsp;<input class='submitbutton' type='submit' name='submit' value='%s' />
	</td>
  </tr>
</table>
</form>
END
,
_('Year'),
_('Month'),
_('Day'),
_('Hours'),
_('Minutes'),
_('Set time')
;
    &closebox();
}


getcgihash(\%par);
loadconfig();
showhttpheaders();
#&openpage(_('NTP configuration'), 1, '<script type="text/javascript" src="/include/serviceswitch.js"></script>');
&openpage(_('NTP configuration'), 1, '');

action();
&openbigbox($errormessage, $warnmessage, $notemessage);
display();
closebigbox();
closepage();
