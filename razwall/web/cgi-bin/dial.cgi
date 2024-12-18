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
require 'header.pl';

my %cgiparams;

$cgiparams{'ACTION'} = '';
&getcgihash(\%cgiparams);
$uplink = $cgiparams{'UPLINK'};
my $cgi = CGI->new ();
$user_agent = $cgi->user_agent();

sub uplinkaction($$) {
    my $uplink = shift;
    my $switch = shift;

    my %uldata = 0;
    my $settingsfile = "${swroot}/uplinks/$uplink/settings";

    return if (! -e $settingsfile);
    readhash($settingsfile, \%uldata);
    if ($switch eq 'start') {
	$uldata{'AUTOSTART'} = 'on';
	&log("Toggle on manually uplink '%s'");
    } elsif ($switch eq 'stop') {
	$uldata{'AUTOSTART'} = 'off';
	&log("Toggle off manually uplink '%s'");
    }
    writehash($settingsfile, \%uldata);

    open (UPLINKSTART, "sudo /etc/rc.d/uplinks $switch $uplink|");
    close UPLINKSTART;
}

sub status
{
        my $status;
        opendir UPLINKS, "/razwall/config/uplinks" or die "Cannot read uplinks: $!";
                foreach my $uplink (sort grep !/^\./, readdir UPLINKS) {
                    if ( -f "${swroot}/uplinks/${uplink}/active") {
                        if ( ! $status ) {
                                $timestr = &age("${swroot}/uplinks/${uplink}/active");
                                print "$uplink:Connected:$timestr\n";
                        } else {
                                $timestr = &age("${swroot}/uplinks/${uplink}/active");
                                print "$uplink:$status:$uplink\n";
                        }
                    } elsif ( -f "${swroot}/uplinks/${uplink}/connecting") {
                        if ( ! $status ) {
                                print "$uplink:Connecting:\n";
                        } else {
                                print "$uplink:Failure:$status\n";
                        }
                    } else {
		    if ( ! $status ) {
		    	print "$uplink:Idle:\n";
                    } else {
		    	print "$uplink:Failure:\n";	
		    }
	    }	
	}
}

# backwards compatible
if ($cgiparams{'ACTION'} eq _('Connect')) {
    uplinkaction($uplink, 'start');
} elsif ($cgiparams{'ACTION'} eq _('Disconnect')) {
    uplinkaction($uplink, 'stop');
}
# action should not be language specific
elsif ($cgiparams{'ACTION'} eq 'Connect') {
    uplinkaction($uplink, 'start');
} elsif ($cgiparams{'ACTION'} eq 'Disconnect') {
    uplinkaction($uplink, 'stop');
}


if ($user_agent eq "EFW-Client") {
  	&showhttpheaders();
  	print status();
	exit;
} else {
	print "Status: 302 Moved\nLocation: /cgi-bin/main.cgi\n\n";
}
