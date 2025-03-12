#!/usr/bin/perl
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
#
# $Id: setddns.pl,v 1.4.2.7 2004/10/12 16:36:10 alanh Exp $
#
# Modded to work with new ZoneEdit update URL - dynamic.zoneedit.com - By Darren Carter, www.citsystems.co.za. 2009/03/15
#

close(STDIN);
#close(STDOUT);
#close(STDERR);

use IO::Socket;
require 'header.pl';

my %settings;
my $filename = "${swroot}/ddns/config";
my $cachefile = "${swroot}/ddns/ipcache";
my $ipcache = 0;

open(FILE, "$filename") or die 'Unable to open config file.';
my @current = <FILE>;
close(FILE);
my $lines = $#current + 1;
#unless($lines) { exit 0; }

my $ip = '';
if ( -f "${swroot}/ddns/behindnat" )
{
    $ip = `/usr/local/bin/detectip`;	
} else {
    if (-f "${swroot}/uplinks/main/data") {
	my %conf_hash = ();
	readhash("${swroot}/uplinks/main/data", \%conf_hash);
	$ip = $conf_hash{'ip_address'};
    }
}
chomp $ip;
if ($ARGV[0] ne '-f')
{
	open(IPCACHE, "$cachefile");
	$ipcache = <IPCACHE>;
	close(IPCACHE);
	chomp $ipcache;
}

if ($ip ne $ipcache)
{
    if ($ARGV[0] eq '-f') {
        system("jobcontrol restart dynaccess");
    } else {
        system("jobcontrol restart dynaccess --force");
    }

	my $id = 0;
	my $success = 0;
	my $line;

	foreach $line (@current)
	{
		$id++;
		chomp($line);
		my @temp = split(/\,/,$line);
		unless ($temp[7] eq "off")
		{
			$settings{'SERVICE'} = $temp[0];
			$settings{'HOSTNAME'} = $temp[1];
			$settings{'DOMAIN'} = $temp[2];
			$settings{'PROXY'} = $temp[3];
			$settings{'WILDCARDS'} = $temp[4];
			$settings{'LOGIN'} = $temp[5];
			$settings{'PASSWORD'} = $temp[6];
			$settings{'ENABLED'} = $temp[7];
			my @service = split(/\./, "$settings{'SERVICE'}");
			$settings{'SERVICE'} = "$service[0]";
			if ($settings{'SERVICE'} eq 'no-ip') {
				$auth = "$settings{'LOGIN'}:$settings{'PASSWORD'}";
				$completeDomain = "$settings{'HOSTNAME'}.$settings{'DOMAIN'}";
				$userAgent = "EFW Update Client info\@endian.com";
				$updatedURL = "http://dynupdate.no-ip.com/nic/update?hostname=$completeDomain";
				if ($ip) {
					$updatedURL = "$updatedURL&myip=$ip";
				}

				my $chld_out = "";
				my $chld_in = "";
				my $curlCmd = "curl -q -A '$userAgent' -u '$auth' '$updatedURL'";

				$chld_out = `$curlCmd`;
				if ($chld_out =~ m/^good/ || $chld_out =~ m/^nochg/) {
					&log("Dynamic DNS ip-update for $completeDomain: success");
					$success++;
				} else {
					&log("Dynamic DNS ip-update for $completeDomain: failure '$chld_out'");
				}
			}
			elsif ($settings{'SERVICE'} eq 'DynAccess')
 			{# reloaded before, just to update the ip cache...
			    $success++;
			}
			elsif ($settings{'SERVICE'} eq 'selfhost')
			{
				my %proxysettings;
				&readhash("/usr/lib/efw/proxy/default/settings", \%proxysettings);
				if (-e "${swroot}/proxy/settings") {
				    &readhash("${swroot}/proxy/settings", \%proxysettings);
                }
				my $peer = 'www.ns4you.de';
				my $peerport = 80;

				if ($proxysettings{'UPSTREAM_ENABLED'} eq "on") {
                    $peer = $proxysettings{'UPSTREAM_SERVER'};
                    $peerport = $proxysettings{'UPSTREAM_PORT'};
				}

				my $sock;
				unless($sock = new IO::Socket::INET (PeerAddr => $peer, PeerPort => $peerport, Proto => 'tcp', Timeout => 5)) {
					die "Could not connect to $peer:$peerport: $@";
					return 1;
				}

			        my $GET_CMD;
				$GET_CMD  = "GET http://www.ns4you.de/cgi-dns/dns.pl?$settings{'LOGIN'}&$settings{'PASSWORD'}&$ip HTTP/1.1\r\n";
				$GET_CMD .= "Host: www.ns4you.de\r\n";
				$GET_CMD .= "Connection: close\r\n\r\n";
				print $sock "$GET_CMD";

				my $out = '';
				while(<$sock>) {
					$out .= $_;
				}
				close($sock);

				if ( $out =~ m/<meta name="ns4you" title="error"/ ) {
					&log("Dynamic DNS ip-update ns4you failure");
				}
				else 
				{
					$out =~ m/<meta name="ns4you" title="url" content="(.*)"/;
					&log("Dynamic DNS ip-update for $1: success");
					$success++;
				}
			}
			elsif ($settings{'SERVICE'} eq 'nsupdate') {
				# Fetch UI configurable values and assemble the host name.

				my $hostName="$settings{'DOMAIN'}";
				if ($settings{'HOSTNAME'} ne "") {
					$hostName="$settings{'HOSTNAME'}.$hostName";
				}
				my $keyName=$settings{'LOGIN'};
				my $keySecret=$settings{'PASSWORD'};

				# Use a relatively long TTL value to reduce load on DNS.
				# Some public Dynamic DNS servers use values around 4 hours,
				# some use values as low as 60 seconds.
				# XXX Maybe we could fetch the master value from the server
				# (not the timed-down version supplied by DNS cache)

				my $timeToLive="3600";

				# Internal setting that can be used to override the DNS server
				# where the update is applied. It can be of use when testing
				# against a private DNS server.
 
				my $masterServer="";

				# Prepare the nsupdate command script to remove and re-add the
				# updated A record for the domain.

				my $cmdFile="/tmp/nsupdate-$hostName-commands";
				my $logFile="/tmp/nsupdate-$hostName-result";
				open(TF, ">$cmdFile");
				if ($masterServer ne "") {
					print TF "server $masterServer\n";
				}
				if ($keyName ne "" && $keySecret ne "") {
					print TF "key $keyName $keySecret\n";
				}
				print TF "update delete $hostName A\n";
				print TF "update add $hostName $timeToLive A $ip\n";
				print TF "send\n";
				close(TF);

				# Run nsupdate with -v to use TCP instead of UDP because we're
				# issuing multiple cmds and potentially long keys, and -d to
				# get diagnostic result output.

				my $result = system("/usr/bin/nsupdate -v -d $cmdFile 2>$logFile");
				if ($result != 0) {
					&log("Dynamic DNS ip-update for $hostName: failure");
					open(NSLOG, "$logFile");
					my @nsLog = <NSLOG>;
					close(NSLOG);
					my $logLine;
					foreach $logLine (@nsLog) {
						chomp($logLine);
						if ($logLine ne "") {
							&log("... $logLine");
						}
					}
				}
				else
				{
					&log("Dynamic DNS ip-update for $hostName: success");
					$success++;
				}

				unlink $cmdFile, $logFile;
			}
			elsif ($settings{'SERVICE'} eq 'freedns-afraid')
			{
				my %proxysettings;
				&readhash("/usr/lib/efw/proxy/default/settings", \%proxysettings);
				if (-e "${swroot}/proxy/settings") {
				    &readhash("${swroot}/proxy/settings", \%proxysettings);
                }
				my $peer = 'freedns.afraid.org';
				my $peerport = 80;

				if ($proxysettings{'UPSTREAM_ENABLED'} eq "on") {
                    $peer = $proxysettings{'UPSTREAM_SERVER'};
                    $peerport = $proxysettings{'UPSTREAM_PORT'};
				}

				my $sock;
				unless($sock = new IO::Socket::INET (PeerAddr => $peer, PeerPort => $peerport, Proto => 'tcp', Timeout => 5)) {
					die "Could not connect to $peer:$peerport: $@";
					return 1;
				}

			        my $GET_CMD;
				$GET_CMD  = "GET http://freedns.afraid.org/dynamic/update.php?$settings{'LOGIN'} HTTP/1.1\r\n";
				$GET_CMD .= "Host: freedns.afraid.org\r\n";
				$GET_CMD .= "Connection: close\r\n\r\n";
				print $sock "$GET_CMD";

				my $out = '';
				while(<$sock>) {
					$out .= $_;
				}
				close($sock);
				
				#Valid responses from service are:
                                #Updated yourdomain.afraid.org to your IP
                                #Address <ip> has not changed.

				if ( $out !~ m/(Updated|Address .* has not changed)/ig ) {
					#cleanup http response...
					$out =~ s/.+?\015?\012\015?\012//s;    # header HTTP
					@out = split("\r", $out);
					&log("Dynamic DNS afraid.org : failure (@out[1])");
				}
				else 
				{
					&log("Dynamic DNS afraid.org : success");
					$success++;
				}
			}
			elsif ($settings{'SERVICE'} eq 'regfish')
			{
				my %proxysettings;
				&readhash("/usr/lib/efw/proxy/default/settings", \%proxysettings);
				if (-e "${swroot}/proxy/settings") {
				    &readhash("${swroot}/proxy/settings", \%proxysettings);
                }
				my $peer = 'www.regfish.com';
				my $peerport = 80;

				if ($proxysettings{'UPSTREAM_ENABLED'} eq "on") {
                    $peer = $proxysettings{'UPSTREAM_SERVER'};
                    $peerport = $proxysettings{'UPSTREAM_PORT'};
				}

				my $sock;
				unless($sock = new IO::Socket::INET (PeerAddr => $peer, PeerPort => $peerport, Proto => 'tcp', Timeout => 5)) {
					die "Could not connect to $peer:$peerport: $@";
					return 1;
				}

			        my $GET_CMD;
				$GET_CMD  = "GET http://www.regfish.com/dyndns/2/?fqdn=$settings{'DOMAIN'}&thisipv4=true&forcehost=1&authtype=secure&token=$settings{'LOGIN'} HTTP/1.1\r\n";
				$GET_CMD .= "Host: www.regfish.com\r\n";
				$GET_CMD .= "Connection: close\r\n\r\n";
				print $sock "$GET_CMD";

				my $out = '';
				while(<$sock>) {
					$out .= $_;
				}
				close($sock);
				
				#Valid responses from service:
				#success|100|update succeeded!
				#success|101|no update needed at this time..

				if ( $out !~ m/(success\|(100|101)\|)/ig ) {
					#cleanup http response...
					$out =~ s/.+?\015?\012\015?\012//s;    # header HTTP
					@out = split("\r", $out);
					&log("Dynamic DNS regfish.com : @out[1]");
				}
				else 
				{
					&log("Dynamic DNS regfish.com : success");
					$success++;
				}
			}
			elsif ($settings{'SERVICE'} eq 'ovh')
			{
				my %proxysettings;
				&readhash("/usr/lib/efw/proxy/default/settings", \%proxysettings);
				if (-e "${swroot}/proxy/settings") {
				    &readhash("${swroot}/proxy/settings", \%proxysettings);
                }
				my $peer = 'www.ovh.com';
				my $peerport = 80;

				if ($proxysettings{'UPSTREAM_ENABLED'} eq "on") {
                    $peer = $proxysettings{'UPSTREAM_SERVER'};
                    $peerport = $proxysettings{'UPSTREAM_PORT'};
				}

				my $sock;
				unless($sock = new IO::Socket::INET (PeerAddr => $peer, PeerPort => $peerport, Proto => 'tcp', Timeout => 5)) {
					die "Could not connect to $peer:$peerport: $@";
					return 1;
				}

				if ($settings{'HOSTNAME'} eq '') {
					$settings{'HOSTDOMAIN'} = $settings{'DOMAIN'};
				}
				else {
					$settings{'HOSTDOMAIN'} = "$settings{'HOSTNAME'}.$settings{'DOMAIN'}";
				}

				my $GET_CMD;
				$GET_CMD  = "GET http://www.ovh.com/nic/update?system=dyndns&hostname=$settings{'HOSTDOMAIN'}&myip=$ip HTTP/1.1\r\n";
				$GET_CMD .= "Host: www.ovh.com\r\n";
				chomp($code64 = encode_base64("$settings{'LOGIN'}:$settings{'PASSWORD'}"));
				$GET_CMD .= "Authorization: Basic $code64\r\n";
			       #$GET_CMD .= "User-Agent: ipcop\r\n";
			       #$GET_CMD .= "Content-Type: application/x-www-form-urlencoded\r\n";
				$GET_CMD .= "\r\n";
				print $sock "$GET_CMD";
																												
				my $out = '';
				while(<$sock>) {
					$out .= $_;
				}
				close($sock);

                                #HTTP response => error (in  Title tag) else text response
			        #Valid responses from service:good,nochg  (ez-ipupdate like)
				#Should use ez-ipdate but "system=dyndns" is not present
				if ( $out =~ m/<Title>(.*)<\/Title>/ig ) {
					&log("Dynamic DNS ovh.com : failure ($1)");
				}
				elsif ($out !~ m/good |nochg /ig) {
					$out =~ s/.+?\015?\012\015?\012//s;    # header HTTP
					@out = split("\r", $out);
					&log("Dynamic DNS ovh.com : failure ($out[1])");
				}
				else {
				        &log("Dynamic DNS ovh.com : success");
					$success++;
				}
			}
			else
			{
				# The command ez-ipupdate has default values for the domains of following services:
				# dhs.org, dyndns.org, dyndns-custom, dyndns-static, dyndns.cx, easydns.com, zoneedit.com
				#
				# The one of zoneedit is out of date, because of this reason was added an if.

				if ($settings{'WILDCARDS'} eq 'on') {$settings{'WILDCARDS'} = '-w';}
				else {$settings{'WILDCARDS'} = '';}

				if ($settings{'SERVICE'} eq 'dyndns-custom' && $settings{'HOSTNAME'} eq '') {$settings{'HOSTDOMAIN'} = $settings{'DOMAIN'};}
				else {$settings{'HOSTDOMAIN'} = "$settings{'HOSTNAME'}.$settings{'DOMAIN'}";}

				if ($settings{'SERVICE'} eq 'zoneedit') {$serverdir = '-s'; $serveradd = 'dynamic.zoneedit.com';}
				else {$serverdir = ''; $serveradd = '';}
			
				my @ddnscommand = ('/usr/bin/ez-ipupdate', '-a', "$ip", '-S', "$settings{'SERVICE'}", "$serverdir", "$serveradd", '-u', "$settings{'LOGIN'}:$settings{'PASSWORD'}", '-h', "$settings{'HOSTDOMAIN'}", "$settings{'WILDCARDS'}", '-q'); 

				my $result = system(@ddnscommand);
				if ( $result != 0) { &log("Dynamic DNS ip-update for $settings{'HOSTDOMAIN'}: failure"); }
				else
				{
					&log("Dynamic DNS ip-update for $settings{'HOSTDOMAIN'}: success");
					$success++;
				}
			}
		}
		else
		{
			# If a line is disabled, then we should discount it
			$lines--;
		}
	}

	if ($lines == $success)
	{
		open(IPCACHE, ">$cachefile");
		flock IPCACHE, 2;
		print IPCACHE $ip;
		close(IPCACHE);
	}
}

# Extracted from Base64.pm
sub encode_base64 ($;$)
{
    my $res = "";
    my $eol = $_[1];
    $eol = "\n" unless defined $eol;
    pos($_[0]) = 0;                          # ensure start at the beginning
    while ($_[0] =~ /(.{1,45})/gs) {
        $res .= substr(pack('u', $1), 1);
        chomp($res);
    }
    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    # break encoded string into lines of no more than 76 characters each
    if (length $eol) {
        $res =~ s/(.{1,76})/$1$eol/g;
    }
    $res;
}
