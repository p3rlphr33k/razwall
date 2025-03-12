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

use IO::Socket;
require 'header.pl';

my %cgiparams;

&showhttpheaders();

&getcgihash(\%cgiparams);

$ENV{'QUERY_STRING'} =~s/&//g;
my @addrs = split(/ip=/,$ENV{'QUERY_STRING'});

my %whois_servers = ("RIPE"=>"whois.ripe.net","APNIC"=>"whois.apnic.net","LACNIC"=>"whois.lacnic.net");

&openpage(_('IP Information'), 1, '');

&openbigbox($errormessage, $warnmessage, $notemessage);

my $addr;
foreach $addr (@addrs) {
next if $addr eq "";

	undef $extraquery;
	undef @lines;
	my $whoisname = "whois.arin.net";
	my $iaddr = inet_aton($addr);
	my $hostname = gethostbyaddr($iaddr, AF_INET);
	if (!$hostname) { $hostname = _('Reverse lookup failed'); }

	my $sock = new IO::Socket::INET ( PeerAddr => $whoisname, PeerPort => 43, Proto => 'tcp');
	if ($sock)
	{
		print $sock "$addr\n";
		while (<$sock>) {
			$extraquery = $1 if (/NetType:    Allocated to (\S+)\s+/);
			push(@lines,$_);
		}
		close($sock);
		if (defined $extraquery) {
			undef (@lines);
			$whoisname = $whois_servers{$extraquery};
			my $sock = new IO::Socket::INET ( PeerAddr => $whoisname, PeerPort => 43, Proto => 'tcp');
			if ($sock)
			{
				print $sock "$addr\n";
				while (<$sock>) {
					push(@lines,$_);
				}
			}
			else
			{
				@lines = ( _('Unable to contact: \'%s\'', $whoisname));
			}
		}
	}
	else
	{
		@lines = ( _('Unable to contact: \'%s\''), $whoisname);
	}

my $hostiplink=" &nbsp;<A HREF=\"http://www.hostip.info/map/index.html?ip=$addr\" TARGET=\"_new\">hostip.info</A>";
	&openbox('100%', 'left', $addr . ' (' . $hostname . ') : '.$whoisname.$hostiplink);

	print "<pre>\n";
	foreach $line (@lines) {
		print &cleanhtml($line,"y");
	}
	print "</pre>\n";
	&closebox();
}

printf <<END
<div align='center'>
<table width='80%'>
<tr>
	<td align='center'><a href='$ENV{'HTTP_REFERER'}'>%s</a></td>
</tr>
</table>
</div>
END
, _('BACK')
;

&closebigbox();

&closepage();
