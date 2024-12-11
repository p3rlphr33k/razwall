#!/usr/bin/perl
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
#
# $Id: status.cgi,v 1.6.2.1 2004/10/25 17:39:58 gespinasse Exp $
#

require 'header.pl';
require '/razwall/web/cgi-bin/endianinc.pl';

my (%netsettings);
&readhash("${swroot}/ethernet/settings", \%netsettings);

my %cgiparams;
# Maps a nice printable name to the changing part of the pid file, which
# is also the name of the program
my %servicenames = (
		    _('CRON server') => ['fcron', '', ''],
		    _('DNS proxy server') => ['dnsmasq', '', ''],
		    _('Logging server') => ['syslog-ng', '', ''],
		    _('Secure Shell server') => ['sshd', '', ''],
		    );

my %partition_names = (
    '/' => _('Main disk'),
    '/var' => _('Data disk'),
    '/var/efw' => _('Configuration disk'),
    '/var/log' => _('Log disk'),
    '/boot' => _('Boot disk'),
    '/mnt/usbstick' => _('Backup disk'),
    '/tmp' => _('Temp')
);


sub openvn_runs {
	my @openvpn_pids = glob('/var/run/openvpn/openvpn.*.pid');
	my $openvpn_running = 1;
	if (! @openvpn_pids) {
		$openvpn_running = 0;
	} else {
		for my $openvpn_pid (@openvpn_pids) {
			if (!isrunning(['openvpn', $openvpn_pid, ''])) {
				$openvpn_running = 0;
			}
		}
	}
	return $openvpn_running;
}

init_register_status(\%servicenames);
# sample
#
# my $froxarr = ['frox', '/var/run/frox/frox.pid', ''];
# register_status(_('FTP virus scanner'), $froxarr);

#
# create a file /razwall/web/cgi-bin/status-<modulename>.pl for each module which
# includes the following: (sample using frox)
#
# require 'header.pl';
# require '/razwall/web/cgi-bin/endianinc.pl';
#
# my $froxarr = ['frox', '/var/run/frox/frox.pid', ''];
# register_status(_('FTP virus scanner'), $froxarr);
# 1;
#


# register status-parts of other modules
foreach my $regfile (glob("/razwall/web/cgi-bin/status-*.pl")) {
    require $regfile;
}

&showhttpheaders();

&getcgihash(\%cgiparams);

&openpage(_('Status information'), 1, '');

&openbigbox($errormessage, $warnmessage, $notemessage);

printf <<END
<table width='100%' cellspacing='0' cellpadding='5'border='0'>
  <tr>
    <td align='left'>
      <a href='#services'>%s</a> |
      <a href='#memory'>%s</a> |
      <a href='#disk'>%s</a> |
      <a href='#uptime'>%s</a> |
      <a href='#modules'>%s</a> |
      <a href='#kernel'>%s</a>
    </td>
  </tr>
</table>
<br>
END
,
_('Services'),
_('Memory'),
_('Disk usage'),
_('Uptime and users'),
_('Loaded modules'),
_('Kernel version')
;

print "<a name='services'></a>\n"; 
&openbox('100%', 'left', _('Services'));

printf <<END
<div class="datagrid" align='center'>
    <table class="ruleslist" style="border-top: 1px solid #cccccc" width='100%' cellspacing='0' border='0'>
END
;

my $lines = 0;
foreach my $key (sort keys(%servicenames)) {
    my $color = 'odd';
    if ($lines % 2) {
        $color = 'even';
    }
    my $statuscolor = "#993333";
    my $textcolor = "#993333";
    my $statuscaption = _('Stopped');
    my $service_running = 0;
    if ($servicenames{$key}[0] ne "openvpn") {
	    $service_running = isrunning($servicenames{$key});
    } else {
	    $service_running = openvn_runs();
    }
    if ($service_running) {
        $statuscolor = "#579903";
        $textcolor = "#000000";
        $statuscaption = _('Running');
    }
    $lines++;

    printf <<END
        <tr class='$color'>
            <td align='left'>$key</td>
            <td align="center" style="text-align: right"><span style="color: $textcolor;">$statuscaption</span></td>
            <td align="center" style="width: 21px"><div style="background-color: $statuscolor; width: 19px; height: 19px; margin-left: 1px"></div></td>
        </tr>
END
;
}


print "</table></div>\n";

&closebox();

print "<a name='memory'></a>\n";
&openbox('100%', 'left', _('Memory'));
print "<table><tr><td><table>";
my ($ram,$size,$used,$free,$percent,$shared,$buffers,$cached);
open(FREE,'/usr/bin/free |');
while(<FREE>)
{
	if ($_ =~ m/^\s+total\s+used\s+free\s+shared\s+buffers\s+cached$/ )
	{
    printf <<END
<tr>
<td>&nbsp;</td>
<td align='center' class='boldbase'><b>%s</b></td>
<td align='center' class='boldbase'><b>%s</b></td>
<td align='center' class='boldbase'><b>%s</b></td>
<td align='left' class='boldbase' colspan='2'><b>%s</b></td>
</tr>
END
,
_('Size'),
_('Used'),
_('Free'),
_('Percentage')
;
  } else {
    if ($_ =~ m/^Mem:\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/) {
      ($ram,$size,$used,$free,$shared,$buffers,$cached) = ($1,$1,$2,$3,$4,$5,$6);
      ($percent = ($used/$size)*100) =~ s/^(\d+)(\.\d+)?$/$1%/;
      printf <<END
<tr>
<td class='boldbase'><b>%s</b></td>
<td align='right'>$size</td>
END
,_('RAM')
;
    } elsif ($_ =~ m/^Swap:\s+(\d+)\s+(\d+)\s+(\d+)$/) {
      ($size,$used,$free) = ($1,$2,$3);
      if ($size != 0)
      {
        ($percent = ($used/$size)*100) =~ s/^(\d+)(\.\d+)?$/$1%/;
      } else {
        ($percent = '');
      }
      printf <<END
<tr>
<td class='boldbase'><b>%s</b></td>
<td align='right'>$size</td>
END
,
_('Swap')
;
    } elsif ($ram and $_ =~ m/^-\/\+ buffers\/cache:\s+(\d+)\s+(\d+)$/ ) {
      ($used,$free) = ($1,$2);
      ($percent = ($used/$ram)*100) =~ s/^(\d+)(\.\d+)?$/$1%/;
      print "<tr><td colspan='2' class='boldbase'><b>"._('-/+ buffers/cache')."</b></td>"
    }
    printf <<END
<td align='right'>$used</td>
<td align='right'>$free</td>
<td>
END
;
    &percentbar($percent);
    printf <<END
</td>
<td align='right'>$percent</td>
</tr>
END
;
  }
}
close FREE;
printf <<END
</table></td><td>
<table>
<tr><td class='boldbase'><b>%s</b></td><td align='right'>$shared</td></tr>
<tr><td class='boldbase'><b>%s</b></td><td align='right'>$buffers</td></tr>
<tr><td class='boldbase'><b>%s</b></td><td align='right'>$cached</td></tr>
</table>
</td></tr></table>
END
,
_('shared'),
_('buffers'),
_('cached')
;
&closebox();

print "<a name='disk'></a>\n";
&openbox('100%', 'left', _('Disk usage'));
print "<table>\n";
open(DF,'/bin/df -P -B M -x rootfs|');
while(<DF>)
{
	if ($_ =~ m/^Filesystem/ )
	{
		printf <<END
<tr>
<td align='left' class='boldbase'><b>%s</b></td>
<td align='left' class='boldbase'><b>%s</b></td>
<td align='center' class='boldbase'><b>%s</b></td>
<td align='center' class='boldbase'><b>%s</b></td>
<td align='center' class='boldbase'><b>%s</b></td>
<td align='left' class='boldbase' colspan='2'><b>%s</b></td>
</tr>
END
,
_('Device'),
_('Mounted on'),
_('Size'),
_('Used'),
_('Free'),
_('Percentage')

;
	}
	else
	{
		my ($device,$size,$used,$free,$percent,$mount) = split(/\s+/, $_);
		printf <<END
<tr>
<td>$device</td>
<td>
END
;
print $partition_names{$mount} || $mount;
print <<END
</td>
<td align='right'>$size</td>
<td align='right'>$used</td>
<td align='right'>$free</td>
<td>
END
;
		&percentbar($percent);
		printf <<END
</td>
<td align='right'>$percent</td>
</tr>
END
;
	}
}
close DF;
print "</table>\n";
&closebox();

print "<a name='uptime'></a>\n";
&openbox('100%', 'left', _('Uptime and users'));
$output = `/usr/bin/w`;
$output = &cleanhtml($output,"y");
print "<pre>$output</pre>\n";
&closebox();


print "<a name='modules'></a>\n";
&openbox('100%', 'left', _('Loaded modules'));
my @lsmod = qx+/sbin/lsmod+;

print '<table>';
foreach my $line (@lsmod) {
    chomp($line);
    ($line = &cleanhtml($line,"y")) =~ s/\[.*\]//g;
    my @split = split(/\s+/, $line);

    @usedby=split(/,/,$split[3]);
    my $printusedby='';
    my $i=1;
    foreach my $module (@usedby) {
	if ($i % 4 != 1) {
	    $printusedby.=',';
	}
	$printusedby.=$module;
	if ($i % 4 == 0) {
	    $printusedby.="<br>";
	}
	$i++;
    }

    printf <<END
  <tr valign="top">
    <td>$split[0]</td>
    <td>$split[1]</td>
    <td>$split[2]</td>
    <td>$printusedby</td>
  </tr>

END
;
}
print "</table>\n";
&closebox();

print "<a name='kernel'></a>\n";
&openbox('100%', 'left', _('Kernel version'));
print "<pre>\n";
$kernel = `/bin/uname -r`;
$kernel =~ s/endian/$brand/;
$kernel =~ s/ //;
print "$kernel"; 
# | sed s/endian/$brand/g`;
print "</pre>\n";
&closebox();

&closebigbox();

&closepage();

sub percentbar
{
  my $percent = $_[0];
  my $fg = '#a0a0a0';
  my $bg = '#e2e2e2';

  if ($percent =~ m/^(\d+)%$/ )
  {
    printf <<END
<table width='100' border='1' cellspacing='0' cellpadding='0' style='border-width:1px;border-style:solid;border-color:$fg;width:100px;height:10px;'>
<tr>
END
;
    if ($percent eq "100%") {
      print "<td width='100%' bgcolor='$fg' style='background-color:$fg;border-style:solid;border-width:1px;border-color:$bg'>"
    } elsif ($percent eq "0%") {
      print "<td width='100%' bgcolor='$bg' style='background-color:$bg;border-style:solid;border-width:1px;border-color:$bg'>"
    } else {
      print "<td width='$percent' bgcolor='$fg' style='background-color:$fg;border-style:solid;border-width:1px;border-color:$bg'></td><td width='" . (100-$1) . "%' bgcolor='$bg' style='background-color:$bg;border-style:solid;border-width:1px;border-color:$bg'>"
    }
    printf <<END
<img src='/images/null.png' width='1' height='1' alt='' /></td></tr></table>
END
;
  }
}

