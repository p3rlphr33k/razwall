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
 
Net::WebSocket::Server->new(
    listen => 4000,
	tick_period => 5,
	on_tick => sub {
		
		# START CPU
        my ($junk, $cpu_user, $cpu_nice, $cpu_sys, $cpu_idle) = split(/\s+/,`sudo cat /proc/stat`);
        my $cpu_total1 = $cpu_user + $cpu_nice + $cpu_sys + $cpu_idle;
        my $cpu_load1 = $cpu_user + $cpu_nice + $cpu_sys;
        sleep 2;
        ($junk, $cpu_user, $cpu_nice, $cpu_sys, $cpu_idle) = split(/\s+/,`sudo cat /proc/stat`);
        my $cpu_total2 = $cpu_user + $cpu_nice + $cpu_sys + $cpu_idle;
        my $cpu_load2 = $cpu_user + $cpu_nice + $cpu_sys;
        my $a = $cpu_load2 - $cpu_load1;
        my $b = $cpu_total2 - $cpu_total1;
        my $CPU =  100.0*$a/$b;
		# END CPU
		
		# START MEM
        my (@LINES) = `sudo cat /proc/meminfo`;
		my $MTotal =$LINES[0]; 
		$MTotal =~ s/MemTotal:\s+//g;
		$MTotal =~ s/\s+kB//g;
		my $MAvailable = $LINES[2]; 
		$MAvailable =~ s/MemAvailable:\s+//g; 
		$MAvailable =~ s/\s+kB//g;
		my $MEM = (($MTotal-$MAvailable)/$MTotal*100);
		# END MEM
		
	    my ($serv) = @_;
		$_->send_utf8("::CPU::" . $CPU ) for $serv->connections;
		$_->send_utf8("::MEM::" . $MEM ) for $serv->connections;
		
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
