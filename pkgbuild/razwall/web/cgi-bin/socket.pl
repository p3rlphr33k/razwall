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
use lib './';
use Net::WebSocket::Server;
 
#my $origin = 'http://example.com';
 
our @UARRAY = ();
 
# Track previous counters in global variables
my $prev_rx = 0;
my $prev_tx = 0;
my $initialized = 0;

sub get_net_stats_diff {
    # Read cumulative totals as before.
    my ($total_rx, $total_tx) = (0, 0);
    open my $fh, '<', '/proc/net/dev' or die "Cannot open /proc/net/dev: $!";
    while (<$fh>) {
        chomp;
        if (/^\s*([^:]+):\s*(.+)$/) {
            my $iface = $1;
            next if $iface eq 'lo';   # ignore loopback
            my $stats = $2;
            my @values = split(/\s+/, $stats);
            $total_rx += $values[0];
            $total_tx += $values[8];
        }
    }
    close $fh;

    # If this is the very first time, just set prev and return 0
    # so we don't get a huge spike from 0 to total on first reading.
    if (!$initialized) {
        $prev_rx = $total_rx;
        $prev_tx = $total_tx;
        $initialized = 1;
        return (0, 0);
    }

    # Calculate the difference
    my $rx_diff = $total_rx - $prev_rx;
    my $tx_diff = $total_tx - $prev_tx;

    # Update prev counters for next tick
    $prev_rx = $total_rx;
    $prev_tx = $total_tx;

    # Return the diff
    return ($rx_diff, $tx_diff);
}


# START NET TX/RX
sub get_net_stats {
	my ($total_rx, $total_tx) = (0, 0);
	open my $fh, '<', '/proc/net/dev' or die "Cannot open /proc/net/dev: $!";
	while (<$fh>) {
		chomp;
		# Match lines like "  eth0:  1234567 .... 8901234 ...", ignoring lo interface
		if (/^\s*([^:]+):\s*(.+)$/) {
			my $iface = $1;
			next if $iface eq 'lo';
			my $stats = $2;
			my @values = split(/\s+/, $stats);
			# The first value (index 0) is received bytes, the ninth value (index 8) is transmitted bytes
			$total_rx += $values[0] + 0;
			$total_tx += $values[8] + 0;
		}
	}
	close $fh;
	return ($total_rx, $total_tx);
}

Net::WebSocket::Server->new(
    listen => 4000,
	tick_period => 5,
	on_tick => sub {

=pod
		# START CPU
        my ($junk, $cpu_user, $cpu_nice, $cpu_sys, $cpu_idle) = split(/\s+/,`cat /proc/stat`);
        my $cpu_total1 = $cpu_user + $cpu_nice + $cpu_sys + $cpu_idle;
        my $cpu_load1 = $cpu_user + $cpu_nice + $cpu_sys;
        sleep 2;
        ($junk, $cpu_user, $cpu_nice, $cpu_sys, $cpu_idle) = split(/\s+/,`cat /proc/stat`);
        my $cpu_total2 = $cpu_user + $cpu_nice + $cpu_sys + $cpu_idle;
        my $cpu_load2 = $cpu_user + $cpu_nice + $cpu_sys;
        my $a = $cpu_load2 - $cpu_load1;
        my $b = $cpu_total2 - $cpu_total1;
        my $CPU =  100.0*$a/$b;
		# END CPU
		
		# START MEM
        my (@LINES) = `cat /proc/meminfo`;
		my $MTotal =$LINES[0]; 
		$MTotal =~ s/MemTotal:\s+//g;
		$MTotal =~ s/\s+kB//g;
		my $MAvailable = $LINES[2]; 
		$MAvailable =~ s/MemAvailable:\s+//g; 
		$MAvailable =~ s/\s+kB//g;
		my $MEM = (($MTotal-$MAvailable)/$MTotal*100);
		# END MEM
=cut
		
		# --- NETWORK Traffic Calculation ---
 #       my ($net_rx, $net_tx) = get_net_stats();
		
		
		# Get the difference in bytes for this interval
        my ($rx_diff, $tx_diff) = get_net_stats_diff();

        # Convert to bytes per second by dividing the difference
        # by the tick interval (5 seconds here).
        # Then convert to KB/s by dividing by 1024.
        my $rx_kbps = ($rx_diff / 5) / 1024.0;
        my $tx_kbps = ($tx_diff / 5) / 1024.0;

        # Send those rate values to clients
        # Example format: "::NETIN::<rx_kbps>"
        # and "::NETOUT::<tx_kbps>"
        
		
	    my ($serv) = @_;
#		$_->send_utf8("::CPU::" . $CPU ) for $serv->connections;
#		$_->send_utf8("::MEM::" . $MEM ) for $serv->connections;
		#$_->send_utf8("::NETIN::" . $net_rx ) for $serv->connections;
		#$_->send_utf8("::NETOUT::" . $net_tx) for $serv->connections;
		$_->send_utf8("::NETIN::"  . sprintf("%.2f", $rx_kbps)) for $serv->connections;
        $_->send_utf8("::NETOUT::" . sprintf("%.2f", $tx_kbps)) for $serv->connections;
		
		my $uarray = join(",", @UARRAY);
		$_->send_utf8("::CONNECTIONS::" . $uarray ) for $serv->connections;
		
	},
	
	on_connect => sub {
        our ($serv, $conn) = @_;
        $conn->on(
			handshake => sub {
            	my ($conn, $handshake) = @_;
            	#$conn->disconnect() unless $handshake->req->origin eq $origin;
            },
			#ready => sub {
            #    my ($conn) = @_;
            #    my $msg = "::Client: connect IP $conn->{ip} PORT $conn->{port}";
            #    $_->send_utf8($msg) for( $serv->connections() );
            #},
            utf8 => sub {
				my ($conn, $msg) = @_;
				our @UARRAY = ();
				my $MyIP = $conn->ip();
				my $MyPT = $conn->port();
				
	        	for ($serv->connections()) {
        		   	my $sIP = $_->ip();
        		   	my $sPT = $_->port();

        		   	push(@UARRAY, $sIP."::".$sPT);
					if($MyPT != $sPT) {
						#$_->send_utf8("::NOMATCH:$MyPT!=$sPT");
						#$_->send_utf8("::NOT MINE:$sIP:$sPT");
						$_->send_utf8($msg);
					}
        		}
				#$_->send_utf8($msg) for( $serv->connections() );
            },
			# binary => sub {
            #    my ($conn, $msg) = @_;
            #    $_->send_binary("::$msg") for( $serv->connections() );
            #},
			#pong => sub {
            #    my ($conn, $msg) = @_;
            #    $_->send_utf8("::$msg") for( $serv->connections() );
            #},
			#disconnect => sub {
            #    my ($conn, $code, $reason) = @_;
            #    $_->send_utf8("::Client: disconnect IP $conn->{ip} PORT $conn->{port}") for( $serv->connections() );
            #},
		);
    },
)->start;
