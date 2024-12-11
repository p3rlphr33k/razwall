#!/usr/bin/perl
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
use CGI();
use Time::Local;
use POSIX;

%months = ( 'Jan' => '0',
	    'Feb' => '1',
	    'Mar' => '2',
	    'Apr' => '3',
	    'May' => '4',
	    'Jun' => '5',
	    'Jul' => '6',
	    'Aug' => '7',
	    'Sep' => '8',
	    'Oct' => '9',
	    'Nov' => '10',
	    'Dec' => '11'
	);

#Replace a string without using RegExp.
sub str_replace {
  my $replace_this = shift;
  my $with_this  = shift; 
  my $string   = shift;
  my $length = length($string);
  my $target = length($replace_this);
			
  for(my $i=0; $i<$length - $target + 1; $i++) {
    if(substr($string,$i,$target) eq $replace_this) {
      $string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
      #return $string; #Comment this if you what a global replace
    }
  }
  return $string;
}

sub get_substrings {
    my $type = @_[0];
    my $line = @_[1];
    my $second = '0';
    my $minute = '0';
    my $hour = '0';
    my $day = '0';
    my $month = '0';
    my $year = '0';
    my $msg = '';
    if ($type eq 'squid') {
	($timestamp,$msg) = $line =~ m/^(\d+)\.\d{3}\s+(.*)/;
        ($second,$minute,$hour,$day,$month,$year,$wday,$yday,$isdst) = localtime $timestamp;
	$year = $year + 1900;
    } elsif ($type eq 'dansguardian') {
	($year,$month,$day,$hour,$minute,$second,$msg) = $line =~ m/^(\d{4})\.(\d{1,2})\.(\d{1,2})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})\s+(.*)/;
	$date = "$year.$month.$day $hour:$minute:$second";
        $month = $month -1;
    } elsif ($type eq 'system' || $type eq 'clamav' || $type eq 'commtouchweb' || $type eq 'panda' || $type eq 'smtp' || $type eq 'openvpn' || $type eq 'firewall' || $type eq 'snort' ) {
	($month,$day,$hour,$minute,$second,$msg) = $line =~ m/^([A-Z][a-z]{2})\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+[A-Za-z0-9_\-\.]+\s+(.*)/;
	@local = localtime();
	$year = $local[5] + 1900;
	$month = $months{$month};
    } elsif ($type eq 'httpd') {
	($msg1,$day,$month,$year,$hour,$minute,$second,$msg2) = $line =~ m/^(.*)\[([0-9]{2})\/([A-Za-z]{3})\/([0-9]{4}):([0-9]{2}):([0-9]{2}):([0-9]{2}).*\](.*)/;
	$msg = $msg1.$msg2;
	$month = $months{$month};
    }
    return ($second, $minute, $hour, $day, $month, $year, $msg);
}

my $logdir = '/var/log';

my %logfiles = (
	     'squid' => "$logdir/squid/access.log_short",
	     'firewall' => "$logdir/firewall",
	     'snort' => "$logdir/snort/alert",
	     'commtouchweb' => "$logdir/c-icap/access.log",
	     'dansguardian' => "$logdir/dansguardian/access.log_short",
	     'openvpn' => "$logdir/openvpn/openvpn.log",
	     'system' => "$logdir/messages",
	     'smtp' => "$logdir/maillog",
	     'clamav' => "$logdir/clamav/clamd.log",
	     'panda' => "$logdir/panda/panda.log",
	     'httpd' => "$logdir/httpd/httpd_access"
	    );

my %checked = ( 
	     'squid' => 1,
	     'firewall' => 1,
	     'snort' => 1,
	     'commtouchweb' => 1,
	     'dansguardian' => 1,
	     'openvpn' => 1,
	     'system' => 1,
	     'smtp' => 1,
	     'clamav' => 1,
	     'panda' => 1,
	     'httpd' => 1
	    );

my %lines = ();

my $line_number = 50;
my $command = '';
my $strlength = 60;
my $helpstring = '';

foreach $type (keys %logfiles) {
    @out_lines = ();
    if ($checked{$type} > 0 && -e $logfiles{$type}) {
	$command = "tail -n $line_number ".$logfiles{$type};
	open(CMD,"$command|");
	while(<CMD>) {
	    push(@out_lines,$_);
	}
	close(CMD);
	for ($i = 0; $i <= $#out_lines; $i++) {
		if (@out_lines[$i] =~ m/.*GET \/cgi\-bin\/.*\-ajax\.cgi.*/) {
		    next;
		}
	        ($second, $minute, $hour, $day, $month, $year, $msg) = get_substrings($type,@out_lines[$i]);
		if (($second ne '0' || $minute ne '0' || $hour ne '0' || $day ne '0' || $month ne '0' || $year > 2000) and $msg ne '') {
	    	    $timestamp = timelocal($second, $minute, $hour, $day, $month, $year);
		    $suffix = '';
		    while (exists($lines{$timestamp.$type.$suffix})) {
			$suffix = $suffix.'+';
		    }
		    my @msgs = $msg =~ m/\S{$strlength,}/g;
		    if ($#msgs >= 0) {
			for ($j = 0; $j <= $#msgs; $j++) {
			    my $length = length(@msgs[$j]);
			    $helpstring = '';
			    for ($k = 0; $k < ceil($length/$strlength); $k++) {
				$helpstring .= substr(@msgs[$j],$strlength * $k,$strlength).' ';
			    }
			    $msg = str_replace(@msgs[$j],$helpstring,$msg);
			}
		    }
    		    $lines{$timestamp.$type.$suffix} = { 'date' => strftime("%Y-%m-%d %H:%M:%S",$second,$minute,$hour,$day,$month,$year-1900),
					    	         'type' => $type,
					    	         'msg' => $msg
							};
		} 
	}
    }
}

$outstring = '';

foreach $entry_id (sort keys %lines) {
    $msg = $lines{$entry_id}{'msg'};
    $type = $lines{$entry_id}{'type'};
    $type =~s/&/&amp;/g;
    $type =~s/'/&quot;/g;
    $msg =~s/&/&amp;/g;
    $msg =~s/'/&quot;/g;
    $msg =~s/</&lt;/g;
    $msg =~s/>/&gt;/g;
    $outstring .= "<entry id='".$entry_id."' type='".$type."' date='".$lines{$entry_id}{'date'}."' text='".$msg."' />\n";
}

print "Cache-Control: no-cache, must-revalidate\r\n";
print "Expires: Mon, 26 Jul 1997 05:00:00 GMT\r\n";
print "Pragma: no-cache\r\n";
print "Content-type: text/xml\r\n\r\n";
print "<?xml version='1.0' encoding='ISO-8859-1'?>\n<logs>\n";
print $outstring;
print "</logs>\n";
