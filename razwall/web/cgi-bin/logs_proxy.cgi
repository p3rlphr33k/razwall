#!/usr/bin/perl
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
#
# $Id: proxylog.dat,v 1.4.2.6 2004/12/01 19:17:07 rkerr Exp $
#

require 'header.pl';
require 'opentsa.pl';
use POSIX();


my %cgiparams;
my %logsettings;
my %ips;
my %save;
my %selected;
my %checked;
my $name;
my %mapip;

my $logfile="/var/log/squid/access.log";
my @files = sort(glob("/var/log/archives/squid/access.log-*.gz"));
my $name = "proxy";


my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

# Enable DNS
my $ip2addr = 'on';
$cgiparams{'SOURCE_IP'} = 'ALL';
$cgiparams{'FILTER'} = "[.](gif|jpeg|jpg|png|css|js)\$";
$cgiparams{'ENABLE_FILTER'} = 'off';
$cgiparams{'ACTION'} = '';
$cgiparams{'SEARCHFILTER'} = "";

&getcgihash(\%cgiparams);
$logsettings{'LOGVIEW_REVERSE'} = 'off';

&readhash("${swroot}/logging/settings", \%logsettings);

if ($logsettings{'LOGVIEW_SIZE'} =~ /^\d+$/) {
    $viewsize = $logsettings{'LOGVIEW_SIZE'};
}

if ($cgiparams{'ACTION'} eq '') {
    $cgiparams{'ENABLE_FILTER'} = 'on';
}

if ($cgiparams{'ACTION'} eq _('Restore defaults')) {
	$cgiparams{'FILTER'} = "[.](gif|jpeg|jpg|png|css|js)\$";
	$cgiparams{'ENABLE_FILTER'} = 'off'; 
}

$save{'FILTER'} = $cgiparams{'FILTER'};
$save{'ENABLE_FILTER'} = $cgiparams{'ENABLE_FILTER'};

&writehash("${swroot}/proxy/viewersettings", \%save);
&readhash("${swroot}/proxy/viewersettings", \%save);

my $filter = "";
if ($cgiparams{'ENABLE_FILTER'} eq 'on') {
    $filter = $cgiparams{'FILTER'};
} else {
    $filter = '';
}

my $sourceip = $cgiparams{'SOURCE_IP'};
my $sourceall = 0;
if ($cgiparams{'SOURCE_IP'} eq 'ALL') {
    $sourceall = 1;
}

sub getDate($) {
    my $now = shift;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime($now);
    $year += 1900;
    $mon++;
    return sprintf("%04d-%02d-%02d", $year, $mon, $mday);
}

sub dateToFilestring($) {
    my $date = shift;
    $date =~ s/\-//g;
    return $date;
}

sub dateToArray($) {
    my $date = shift;
    $date =~ s/\-//g;
    my @datearr = ($date =~ /^(\d{4})(\d{2})(\d{2})$/);
    return \@datearr;
}

sub stringToDate($) {
    my $date = shift;
    my $arr = dateToArray($date);
    return $lala = mktime(0, 0, 0, @$arr[2], @$arr[1] - 1, @$arr[0] - 1900);
}

my $today = getDate(time);
my $date = $today;

if ($cgiparams{'DATE'} =~ /[\d\-]+/) {
    $date = $cgiparams{'DATE'};
}


my $searchfilter = $cgiparams{'SEARCHFILTER'};

my $filetotal=scalar(@files);

my ($firstdatestring) = ($files[0] =~ /\-(\d+).gz$/);
if ($firstdatestring eq '') {
    $firstdatestring = dateToFilestring($today);
}

if ((dateToFilestring($date) < $firstdatestring) || (dateToFilestring($date) > dateToFilestring($today))) {
    $date = $today;
}

my $filestr = $logfile;
if ($date ne $today) {
    $filestr="/var/log/archives/squid/access.log-".dateToFilestring($date).".gz";
}
my $hostname = $settings{'HOSTNAME'};

if (!(open (FILE,($filestr =~ /.gz$/ ? "gzip -dc $filestr |" : $filestr)))) {
    $errormessage = _('No (or only partial) logs exist for the given day').": "._('%s could not be opened', $filestr);
}

my $lines = 0;
my @log = ();


my $thiscode = '$temp =~ /$filter/;';
eval($thiscode);
if ($@ ne '') {
    $errormessage = _('Bad ignore filter: %s', $@)."<P>";
    $filter = '';
}



if (!$skip) {
    foreach my $line (<FILE>) {
        my ($month,$day,$time,$host,$prog,$datetime,$size,$ip,$code,$size2,$method,$url,$user, $through, $mime) = split(/\s+/, $line);

	if (! $ips{$ip}) {
	    $ips{$ip} = 1;
	} else {
	    $ips{$ip}++;
	}
	
	if ($url =~ /$filter/) {
	    next;
	}
	if (! $sourceall && ($ip ne $sourceip)) {
	    next;
	}
	if ($ip eq 'localhost' || $ip eq '127.0.0.1') {
	    next;
	}
	if (($searchfilter !~ /^$/) && ($line !~ /$searchfilter/)) {
	    next;
	}

	my ($SECdt, $MINdt, $HOURdt, $DAYdt, $MONTHdt, $YEARdt) = localtime($datetime);
	$HOURdt = '00'.$HOURdt; $HOURdt =~ s/^.*(..)$/\1/;
	$MINdt = '00'.$MINdt; $MINdt =~ s/^.*(..)$/\1/;
	$SECdt = '00'.$SECdt; $SECdt =~ s/^.*(..)$/\1/;

	$DAYdt = '00'.$DAYdt; $DAYdt =~ s/^.*(..)$/\1/;
	$MONTHdt = $abbr[$MONTHdt];
	$YEARdt = $YEARdt + 1900;

	$log[$lines] = "$YEARdt/$MONTHdt/$DAYdt $HOURdt:$MINdt:$SECdt $ip $user $url";
	$lines++;
    }
    close (FILE);
}


if ($cgiparams{'ACTION'} eq _('Export')) {
    my $datestr = dateToFilestring($date);
    print <<EOF
Content-type: text/plain
Cache-Control: no-cache
Connection: close
Content-Disposition: attachement; filename="${hostname}-${name}-${datestr}.log"
EOF
;

    if ($filter eq '') {
	print _("%s %s log of day %s.", $brand ,$product ,$date);
    } else {
	print _("%s %s log of day %s with filter '%s'.", $brand ,$product, $date, $filter);
    }

    print "Source IP: $cgiparams{'SOURCE_IP'}\r\n";
    if ($cgiparams{'ENABLE_FILTER'} eq 'on') {
	print "Ignore filter: $cgiparams{'FILTER'}\r\n";
    }
    print "\r\n";
    print "\n";

    if ($logsettings{'LOGVIEW_REVERSE'} eq 'on') { @log = reverse @log; }

    foreach my $line (@log) {
	print "$line\r\n";
    }
    exit 0;
}

$selected{'SOURCE_IP'}{$cgiparams{'SOURCE_IP'}} = "selected='selected'";

$checked{'ENABLE_FILTER'}{'off'} = '';
$checked{'ENABLE_FILTER'}{'on'} = '';
$checked{'ENABLE_FILTER'}{$cgiparams{'ENABLE_FILTER'}} = "checked='checked'";

&showhttpheaders();

#
# Opentsa begin
#

$action1 = _('Verify log signature');
$action2 = _('Sign log');
$ts_file_gz = "/var/log/archives/squid/access.log-".dateToFilestring($date).".gz";
$ts_file_tsr = "/var/log/archives/squid/access.log-".dateToFilestring($date).".tsr";
$ts_file_zd = "/var/log/archives/squid/access.log-".dateToFilestring($date).".zd";
if ($cgiparams{'ACTION'} eq $action1) {
    if ($date ne $today) {
	$file = $ts_file_gz;
	if(opentsa_check_file($file) == 0){
	    $notemessage = _("Time stamp is correct!");
	}else{
	    $errormessage = _("Time stamp is not correct! You may control your public key at the opentsa settings.");
	}
    }else{
	$errormessage = _("Only archived logs can be verfied!");
    }
}
if ($cgiparams{'ACTION'} eq $action2) {
    if ($date ne $today) {
	$file = $ts_file_gz;
	if(opentsa_timestamp_file($file) == 0){
	    $notemessage = _("Log signed.");
	}else{
	    $errormessage = _("Could not sign log! You may control your network connection and your opentsa settings.");
	}
    }else{
	$errormessage = _("Only archived logs can be time stamped!");
    }
}

sub time_stamp_html() {
    if ($date ne $today && -e $ts_file_gz && !-e $ts_file_tsr && !-e $ts_file_zd) {
	return "<td align='center'><input class='submitbutton' type='submit' name='ACTION' value='".$action2."' /></td>";
    }else{
	return '';
    }
}

sub check_time_stamp_html() {
    if ($date ne $today && (-e $ts_file_tsr || -e $ts_file_zd)) {
	return "<td align='center'><input class='submitbutton' type='submit' name='ACTION' value='".$action1."' /></td>";
    }else{
	return '';
    }
}

# Opentsa end
#


$extraheaders = <<EOF
<script type="text/javascript" src="/include/jquery.min.js"></script>
<script type="text/javascript" src="/include/jquery.ui.core.min.js"></script>
<script type="text/javascript" src="/include/jquery.ui.datepicker.min.js"></script>
<style type="text/css">\@import url(/include/jquery-ui-core.css);</style>
<style type="text/css">\@import url(/include/jquery-ui-datepicker.css);</style>
<style type="text/css">\@import url(/include/jquery-ui-theme.css);</style>
EOF
;
 
$language = $settings{'LANGUAGE'};
if (-e "/razwall/web/html/include/i18n/jquery.ui.datepicker-$language.js") {
    $extraheaders .= <<EOF
<script type="text/javascript" src="/include/i18n/jquery.ui.datepicker-$language.js"></script>
EOF
;
}

my $firstdatearr = dateToArray($firstdatestring);
my $lastdatearr = dateToArray($today);

$extraheaders .= <<EOF
<script>
  \$(document).ready(function(){
    \$('#calendar').datepicker(
			    {dateFormat: 'yy-mm-dd',
			    minDate: new Date(@$firstdatearr[0], @$firstdatearr[1]-1, @$firstdatearr[2]),
			    maxDate: new Date(@$lastdatearr[0], @$lastdatearr[1]-1, @$lastdatearr[2]),
			    speed: 'immediate'
			    });
  });
</script>
EOF
;


my $offset = 1;
if ($cgiparams{'OFFSET'} =~ /\d+/) {
    $offset = $cgiparams{'OFFSET'};
}
if ($offset < 1) {
    $offset = 1;
}
my $totaloffset=POSIX::ceil($lines/$viewsize);
if ($offset > $totaloffset) {
    $offset = $totaloffset;
}

&openpage(_('Proxy log viewer'), 1, $extraheaders);

&openbigbox($errormessage, $warnmessage, $notemessage);

&openbox('100%', 'left', _('Settings'));

printf <<END
<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
<table width='100%'>
  <tr>
    <td width='5%' class='base'>%s:</td>
    <td width='30%'><input type="text" size="40" name='SEARCHFILTER' VALUE="$searchfilter"></td>

    <td width='15%' class='base'>%s:</td>
    <td width='10%'>
      <select name='SOURCE_IP'>
        <option value='ALL' $selected{'SOURCE_IP'}{'ALL'}>%s</option>
END
,
_('Filter'),
_('Source IP'),
_('ALL')
;
foreach my $ip (sort keys %ips) {
#Selectbox
    my $name = ip2addr($ip);
    print "<option value='$ip' $selected{'SOURCE_IP'}{$ip}>$name</option>\n";
}


printf <<END
      </select>
    </td>
  </tr>
  <tr>
    <td>%s:</td>
    <td><input type='text' name='FILTER' value='$cgiparams{'FILTER'}' size='40' /></td>
    <td>%s:</td>
    <td><input type='checkbox' name='ENABLE_FILTER' value='on' $checked{'ENABLE_FILTER'}{'on'} /></td>
  </tr>
  <tr>
    <td colspan="2">%s: <input type="text" SIZE="9" id="calendar" name='DATE' VALUE="$date"></td>

    <td colspan="2">%s: <input type="text" SIZE="2" name='OFFSET' VALUE="$offset"></td>
  </tr>
</table>
<div align='center'>
<table width='50%'>
  <tr>
    <td align='center'><input class='submitbutton' type='submit' name='ACTION' value='%s' /></td>
    <td width='10%' align='center'><input class='submitbutton' type='submit' name='ACTION' value='%s' /></td>
    <td width='10%' align='center'><input class='submitbutton' type='submit' name='ACTION' value='%s' /></td>
    %s
    %s
  </tr>
</table>
</div>
</form>
END
,
_('Ignore filter'),
_('Enable ignore filter'),
_('Jump to Date'),
_('Jump to Page'),
_('Restore defaults'),
_('Update'),
_('Export'),
time_stamp_html(),
check_time_stamp_html()
;

&closebox();

&openbox('100%', 'left', _('log'));
print "<p><b>"._('Total number of firewall hits for day %s', $date).":  $lines - " . _('Page %s of %s', $offset, $totaloffset)."</b></p>";

my $start = $lines - ($viewsize * $offset);
my $prev = $offset+1;
my $next = $offset-1;
my $prevday = $date;
my $nextday = $date;

if ($start <= 0) { 
    $start = 0;
    $prev = 1;
    my $daybefore = getDate(stringToDate($date)-86400);
    if (dateToFilestring($daybefore) >= $firstdatestring) {
	$prevday = $daybefore;
    } else {
	$prev = -1;
    }
}
if ($next < 1) {
    $next = 1;
    $next = 99999999999;
    my $dayafter = getDate(stringToDate($date)+86400);
    if (dateToFilestring($dayafter) <= dateToFilestring($today)) {
	$nextday = $dayafter;
    } else {
	$next = -1;
    }
}

&oldernewer();

printf <<END
<table width='100%' class="ruleslist" cellspacing="0" cellpadding="0">
  <tr>
    <td width='18%' align='center' class='boldbase'><b>%s</b></td>
    <td width='8%' align='center' class='boldbase'><b>%s</b></td>
    <td width='8%' align='center' class='boldbase'><b>%s</b></td>
    <td width='66%' align='center' class='boldbase'><b>%s</b></td>
  </tr>
END
,
_('Time'),
_('Source IP'),
_('Username'),
_('URL')
;

my @slice = splice(@log, $start, $viewsize);

if ($logsettings{'LOGVIEW_REVERSE'} eq 'on') { @slice = reverse @slice; }

my $i = 0;
my $currentcolor = 0;
my %map = ();

foreach my $line (@slice) {
    if ($i % 2) {
	print "<tr class='even'>\n";
    } else {
	print "<tr class='odd'>\n";
    }
    my ($date, $time,$ip,$user,$url) = split(/\s+/, $line);
    $url =~ /(^.{0,60})/;
    my $part = $1;
    unless (length($part) < 60) { $part = "${part}..."; }  
    $url = &cleanhtml($url,"y");
    $part = &cleanhtml($part,"y");
    my $name = ip2addr($ip);
    if (!($map{$ip})) {
	get_colors();	
	$map{$ip} = $color;
    }
    printf <<END
	<td align='center'>$date $time</td>
	<td align='center' $map{$ip}>$name</td>
	<td align='center'>$user</td>
	<td align='left'><a href='$url' title='$url' target='_new'>$part</a></td>
      </tr>
END
;
    $i++;
}

print "</table>";


if ($#slice > 10) {
    &oldernewer();
}

&closebox();

&closebigbox();

&closepage();

sub oldernewer {
    printf <<END
<table width='100%'>
  <tr>
END
;

    print "<td align='center' width='50%'>";
    if ($prev != -1) {
printf <<END
<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
    <input type="hidden" name="OFFSET" value="$prev">
    <input type="hidden" name="DATE" value="$prevday">
    <input type="hidden" name="FILTER" value="$filter">
    <input type="hidden" name="SEARCHFILTER" value="$searchfilter">
    <input class='submitbutton' type="submit" name="ACTION" value="%s">
</form>
END
,_('Older')
;
    } else {
	print _('Older');
    }
    print "</td>\n";

    print "<td align='center' width='50%'>";
    if ($next != -1) {
printf <<END
<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
    <input type="hidden" name="OFFSET" value="$next">
    <input type="hidden" name="DATE" value="$nextday">
    <input type="hidden" name="FILTER" value="$filter">
    <input type="hidden" name="SEARCHFILTER" value="$searchfilter">
    <input class='submitbutton' type="submit" name="ACTION" value="%s">
</form>
END
,_('Newer')
;
    } else {
	print _('Newer');
    }
    print "</td>\n";

    printf <<END
</tr>
</table>
END
;
}

###############################
# get colors
###############################
sub get_colors() {
    my @colors = (
		  "style='color: #CC0000'",
		  "style='color: #FF9900'",
		  "style='color: #009900'",
		  "style='color: #33CCCC'",
		  "style='color: #CC33CC'",
		  "style='color: #333333'",
		  "style='color: #000099'",
		  );
    if ( $currentcolor > $#colors ) { $currentcolor = 0; }
    $color = $colors[$currentcolor];
    $currentcolor++;
}

################################
# Resolv IPs to hostnames
################################
sub ip2addr() {
    undef $name;
    if ( $ip2addr eq 'on' ) {
	my $ip = shift;
	use Socket;
	my $addr = inet_aton($ip);
	if ( !( $mapip{$ip} ) ) {
	    $mapip{$ip} = gethostbyaddr( $addr, AF_INET );
	}
	if ( !( $mapip{$ip} ) ) {
	    $mapip{$ip} = $ip;
	}
	return $name = $mapip{$ip};
    }
    if (!($name)) { $name = $ip }
}
