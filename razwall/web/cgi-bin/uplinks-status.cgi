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

use strict;
use warnings;
use CGI;
use JSON;
use File::stat;
use Time::localtime;
use File::Basename;

# Constants
my $UPLINKS_DIR = "/razwall/config/uplinks";
my $uplinks_cmd = "sudo /etc/rc.d/uplinks %s %s --with-hooks";

# Initialize CGI
my $cgi = CGI->new;

# Demo flag simulation
my $demo = 0;

# Helper functions

sub list_ {
    init(); # Send the HTTP header (Content-Type)
    
    # Retrieve information about uplinks
    my $info = $pool->info(); # Replace with actual call to fetch uplink info
    my @link_infos;

    foreach my $link (@$info) {
        my $uplink = $link->{'uplinkChain'}[0];
        $uplink->{'uptime'} = age($uplink->{'name'});

        # Get additional information about the uplink
        my $uplink_info = $pool->get($uplink->{'name'}); # Replace with actual method
        $uplink->{'data'} = uplink_data($uplink_info);

        push @link_infos, $uplink;
    }

    # Output JSON-encoded list of uplink data
    print to_json(\@link_infos);
}

sub to_date {
    my ($timestamp) = @_;
    return "" if $timestamp == 0;

    my $tm = localtime($timestamp);
    return sprintf("%02d:%02d:%02d", $tm->hour, $tm->min, $tm->sec);
}

sub age {
    my ($uplink) = @_;
    my $active_file = sprintf("%s/%s/active", $UPLINKS_DIR, $uplink);

    return "" unless -e $active_file;

    my $stat = stat($active_file);
    my $now  = time();
    my $unixsecs = $now - $stat->mtime;

    my $days = int($unixsecs / 86400);
    my $totalhours = int($unixsecs / 3600);
    my $hours = $totalhours % 24;
    my $totalmins = int($unixsecs / 60);
    my $mins = $totalmins % 60;
    my $secs = $unixsecs % 60;

    return sprintf("%sd %sh %sm %ss", $days, $hours, $mins, $secs);
}

sub init {
    print $cgi->header('application/json');
}

sub change_status {
    my ($uplink, $status) = @_;
    my $cmd = sprintf($uplinks_cmd, $status, $uplink);
    return system($cmd) == 0;
}

sub manage_flag {
    my ($uplink, $flag) = @_;
    my $settings_file = "$UPLINKS_DIR/$uplink/settings";
    
    open my $fh, "+<", $settings_file or die "Cannot open $settings_file: $!";
    my @lines = <$fh>;
    seek($fh, 0, 0);

    foreach my $line (@lines) {
        if ($line =~ /^MANAGED=/) {
            $line = $flag ? "MANAGED=on\n" : "MANAGED=off\n";
        }
        print $fh $line;
    }

    truncate($fh, tell($fh));
    close $fh;
}

sub uplink_data {
    my ($uplink_info) = @_;
    return {
        ip          => $uplink_info->{address},
        type        => $uplink_info->{WAN_TYPE},
        interface   => $uplink_info->{interface},
        gateway     => $uplink_info->{gateway},
        last_retry  => to_date($uplink_info->{failure_timestamp}),
    };
}

# Main actions
#my $action = $cgi->param('action') // 'list';
my $action = defined $params{'action'} ? $params{'action'} : 'list';

my $uplink = $cgi->param('uplink');

if ($demo || !$action || $action eq "list") {
    init();
    my $info = {}; # Fetch pool info here
    print to_json($info);
} elsif ($action eq "start") {
    change_status($uplink, "start");
} elsif ($action eq "stop") {
    change_status($uplink, "stop");
} elsif ($action eq "manage") {
    manage_flag($uplink, 1);
} elsif ($action eq "unmanage") {
    manage_flag($uplink, 0);
} elsif ($action eq "status") {
    init();
    my $info = {}; # Fetch uplink status here
    print to_json($info);
} else {
    print $cgi->header('text/plain'), "Unknown action: $action\n";
}

exit;
