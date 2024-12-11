#!/usr/bin/perl
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
#
# Copyright (C) 18-03-2002 Mark Wormgoor <mark@wormgoor.com>
#              - Added links to Snort database and ipinfo.cgi
#
# $Id: ids.dat,v 1.6.2.2 2004/09/15 13:27:09 alanh Exp $
#
require 'header.pl';
require 'opentsa.pl';
use POSIX();

my %cgiparams;
my %logsettings;

my $logfile="/var/log/snort/alert";
my @files = sort(glob("/var/log/archives/snort/alert-*.gz"));
my $name = "ids";

&getcgihash(\%cgiparams);
$logsettings{'LOGVIEW_REVERSE'} = 'off';

&readhash("${swroot}/logging/settings", \%logsettings);

if ($logsettings{'LOGVIEW_SIZE'} =~ /^\d+$/) {
    $viewsize = $logsettings{'LOGVIEW_SIZE'};
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

my $filter = $cgiparams{'FILTER'};

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
    $filestr="/var/log/archives/snort/alert-".dateToFilestring($date).".gz";
}
my $hostname = $settings{'HOSTNAME'};

my $lines = 0;
my ($title,$classification,$priority,$time,$srcip,$srcport,$destip,$destport, $sid, @refs);

&processevent;

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
	print _("%s %s log of day %s.", $brand, $product, $date);
    } else {
	print _("%s %s log of day %s with filter '%s'.", $brand, $product, $date, $filter);
    }
    print "\n";
    print "\n";


    if ($logsettings{'LOGVIEW_REVERSE'} eq 'on') { @log = reverse @log; }

    foreach my $line (@log) {
	my ($datetime,$title,$priority,$classification,$srcip,$srcport,$destip,$destport,$sid,$refs) = split(/\|/, $line);
	$refs =~ s/,$//;
	print "Date: $datetime\n";
	print "Name: $title\n";
	print "Priority: $priority\n";
	print "Type: $classification\n";
	print "IP Info: ";
	print "$srcip";
	if ($srcpport != "n/a") {
	    print ":$srcport";
	}
	print " -> ";
	print "$destip";
	if ($destpport != "n/a") {
	    print ":$destport";
	}
	print "\n";
	print "SID: $sid\n";
	print "Refs: $refs\n\n";
    }

    exit;
}

&showhttpheaders();

#
# Opentsa begin
#

$action1 = _('Verify log signature');
$action2 = _('Sign log');
$ts_file_gz = "/var/log/archives/snort/alert-".dateToFilestring($date).".gz";
$ts_file_tsr = "/var/log/archives/snort/alert-".dateToFilestring($date).".tsr";
$ts_file_zd = "/var/log/archives/snort/alert-".dateToFilestring($date).".zd";
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
#
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

&openpage(_('IDS log viewer'), 1, $extraheaders);

&openbigbox($errormessage, $warnmessage, $notemessage);

&openbox('100%', 'left', _('Settings'));

printf <<END
<form method='post' enctype='multipart/form-data' action='$ENV{'SCRIPT_NAME'}'>
<table width='100%'>
  <tr>
    <td width='5%' class='base'>%s:</td>
    <td width='10%'><input type="text" size="25" name='FILTER' VALUE="$filter"></td>

    <td width='20%' align='right' class='base'>%s:</td>
    <td width='20%'><input type="text" SIZE="9" id="calendar" name='DATE' VALUE="$date"></td>

    <td width='20%' align='right' class='base'>%s:</td>
    <td width='5%'><input type="text" SIZE="2" name='OFFSET' VALUE="$offset"></td>

    <td width='10%' align='center'><input class='submitbutton' type='submit' name='ACTION' value='%s' /></td>
    <td width='10%' align='center'><input class='submitbutton' type='submit' name='ACTION' value='%s' /></td>
  </tr>
  <tr>
    %s
    %s
  </tr>
</table>
</form>
END
,
_('Filter'),
_('Jump to Date'),
_('Jump to Page'),
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
END
;

my @slice = splice(@log, $start, $viewsize);

if ($logsettings{'LOGVIEW_REVERSE'} eq 'on') { @slice = reverse @slice; }

my $i = 0;
foreach my $line (@slice) {
    if ($i % 2) {
	print "<tr class='even'><td>\n";
    } else {
	print "<tr class='odd'><td>\n";
    }
    my ($datetime,$title,$priority,$classification,$srcip,$srcport,$destip,$destport,$sid,$refs) = split(/\|/, $line);
    printf <<END
<table width='100%'>
  <tr>
    <td width='80'><b>%s:</b></td><td width='100'>$datetime</td>
    <td width='65'><b>%s:</b></td><td>$title</td>
  </tr>
  <tr>
    <td><b>%s:</b></td><td>$priority</td>
    <td><b>%s:</b></td><td>$classification</td>
  </tr>
  <tr>
    <td><b>%s:</b></td>
    <td colspan='3'>
END
,
_('Date'),
_('Name'),
_('Priority'),
_('Type'),
_('IP info')
;
    if ($srcip ne "n/a") {
	print "<a href='/cgi-bin/ipinfo.cgi?ip=$srcip'>$srcip</a>";
    } else {
	print "$srcip";
    }
    print ":$srcport -&gt; ";
    if ($destip ne "n/a") {
	print "<a href='/cgi-bin/ipinfo.cgi?ip=$destip'>$destip</a>";
    } else {
	print "$destip";
    }
    print ":$destport";
printf <<END
    </td>
  </tr>
  <tr>
    <td valign='top'><b>%s:</b></td>
    <td valign='top'>
END
,_('References')
;
    foreach my $ref (split(/,/,$refs)) {
	if ($ref =~ m/url (.*)/) {
	    print "<a href='http://$1'>$1</a><br />";
	} elsif ($ref =~ m/cve (.*)/) {
	    print "<a href='http://cve.mitre.org/cgi-bin/cvename.cgi?name=$1'>$1</a><br />";
	} elsif ($ref =~ m/nessus (.*)/) {
	    print "<a href='http://cgi.nessus.org/plugins/dump.php3?id=$1'>Nessus $1</a><br />";
	} elsif ($ref =~ m/bugtraq (.*)/) {
	    print "<a href='http://www.securityfocus.com/bid/$1'>Bugtraq $1</a><br />";
	} else {
	    print "$ref<br />";
	}
    }
    print _('none found') unless $refs =~ /,/;
    printf <<END
    <td valign='top'><b>SID:</b></td>
    <td valign='top'>
END
;
    if ($sid ne "n/a") {
	print "<a href='http://www.snort.org/pub-bin/sigs.cgi?sid=1-$sid' ";
	print "target='_blank'>$sid</a></td>\n";
    } else {
	print $sid;
    }
    printf <<END
  </tr>
</table>
</td></tr>
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

sub processevent {
    if (!(open (FILE,($filestr =~ /.gz$/ ? "gzip -dc $filestr |" : $filestr)))) {
	$errormessage = _('No (or only partial) logs exist for the given day').": "._('%s could not be opened', $filestr);
    }

    my $i = 0;
    foreach my $line (<FILE>) {

	if (($filter !~ /^$/) && ($line !~ /$filter/)) {
	    next;
	}
	next if ($line !~ /\[.*\{.*\->/);

	$i++;
	($title,$classification,$priority,$date,$time,$srcip,$srcport,$destip,$destport, $sid) = ("n/a","n/a","n/a","n/a","n/a","n/a","n/a","n/a","n/a", "n/a");
	@refs = ();
	if ($line =~ m/:[0-9]{1,4}\] ([^\[{]*)/) {
	    $title = &cleanhtml($1,"y");
	}

	if ($line =~ m/Classification: (.*)\] \[Priority: (\d)\]/) {
	    $classification = &cleanhtml($1,"y");
	    $priority = $2;
	}
	if ($line =~ m/([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3}) \-\> ([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/) {
	    $srcip = $1 . "." . $2 . "." . $3 . "." . $4;
	    $destip = $5 . "." . $6 . "." . $7 . "." . $8;
	}
	if ($line =~ m/([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\:([0-9]{1,6}) \-\> ([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\:([0-9]{1,6})/) {
	    $srcip = $1 . "." . $2 . "." . $3 . "." . $4;
	    $srcport = $5;
	    $destip = $6 . "." . $7 . "." . $8 . "." . $9;
	    $destport = $10;
	}

	if ($line  =~ m/^(\S+\s+\d+)\s+(\d{2}:\d{2}:\d{2})\s+/) {
	    ($date,$time) = ($1,$2);
	}
	if ($line =~ m/\[Xref \=\>.*\]/) {
	    $line =~ s/\]\[Xref \=\> /, /g;
	    $line =~ m/\[Xref \=\> (.*)\]/;
	    push(@refs, $1);
	}
	if ($line =~ m/\[1:([0-9]+):[0-9]+\]/) {
	    $sid = $1;
	}
	$i++;
	unless ($i == 1) { &append; }
    }
    close(LOG);
}

sub append {
    $log[$lines] = "$date $time|$title|$priority|$classification|$srcip|$srcport|$destip|$destport|$sid|";
    foreach my $line (@refs) {
	$log[$lines] = "$log[$lines]$line,";
    }
    $lines++;
}


sub oldernewer {
    printf <<END
<table width='100%'>
  <tr>
END
;

    print "<td align='center' width='50%'>";
    if ($prev != -1) {
printf <<END
<form method='post' action='$ENV{'SCRIPT_NAME'}'>
    <input type="hidden" name="OFFSET" value="$prev">
    <input type="hidden" name="DATE" value="$prevday">
    <input type="hidden" name="FILTER" value="$filter">
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
<form method='post' action='$ENV{'SCRIPT_NAME'}'>
    <input type="hidden" name="OFFSET" value="$next">
    <input type="hidden" name="DATE" value="$nextday">
    <input type="hidden" name="FILTER" value="$filter">
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
