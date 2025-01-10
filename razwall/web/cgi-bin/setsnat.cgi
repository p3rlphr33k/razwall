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
#use strict;
use warnings;



	#	iptables -t nat -F PORTFW
	#	iptables -F PORTFWACCESS
	#	iptables -t nat -F POSTPORTFW
	
	#	on,tcp,,any,24.111.67.51:UPLINK:main,,80,192.168.19.14,80,DNAT,internal www server,,ACCEPT
	#	enabled			on
	#	proto			tcp
	#	src_dev			
	#	src_ip			any
	#	dst_dev			24.111.67.51:UPLINK:main
	#	dst_ip			
	#	dst_port		80
	#	target_ip		192.168.19.14
	#	target_port		80
	#	nat_target		DNAT
	#	remark			internal www server
	#	log				
	#	filter_target	ACCEPT
	#	random			
	#	iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.51 -j DNAT -p tcp --dport 80 --to-destination 192.168.19.14:80
	#	iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.14 -p tcp --dport 80 -j ACCEPT
	
	#	on,tcp,,any,24.111.67.51:UPLINK:main,,443,192.168.19.14,443,DNAT,inernal www SSL server,,ACCEPT
	#	enabled			on
	#	proto			tcp
	#	src_dev			
	#	src_ip			any
	#	dst_dev			24.111.67.51:UPLINK:main
	#	dst_ip			
	#	dst_port		443
	#	target_ip		192.168.19.14
	#	target_port		443
	#	nat_target		DNAT
	#	remark			internal www SSL server
	#	log				
	#	filter_target	ACCEPT
	#	random			
	#	iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.51 -j DNAT -p tcp --dport 443 --to-destination 192.168.19.14:443
	#	iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.14 -p tcp --dport 443 -j ACCEPT

	#	on,tcp&udp,,any,24.111.67.54:UPLINK:main,,80&443,192.168.19.46,,DNAT,Mobile Print Server,,ALLOW
	#	enabled			on
	#	proto			tcp&udp
	#	src_dev			
	#	src_ip			any
	#	dst_dev			24.111.67.54:UPLINK:main
	#	dst_ip			
	#	dst_port		80&443
	#	target_ip		192.168.19.46
	#	target_port		
	#	nat_target		DNAT
	#	remark			Mobile Print Server
	#	log				
	#	filter_target	ALLOW
	#	random
	#	## TCP&UDP ALSO 80&443 SO 4 RULES TOTAL:
	#	iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p tcp --dport 80 --to-destination 192.168.19.46
	#	iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p tcp --dport 80 -j ALLOW
	#	iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p udp --dport 80 --to-destination 192.168.19.46
	#	iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p udp --dport 80 -j ALLOW
	#	iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p tcp --dport 443 --to-destination 192.168.19.46
	#	iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p tcp --dport 443 -j ALLOW
	#	iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p udp --dport 443 --to-destination 192.168.19.46
	#	iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p udp --dport 443 -j ALLOW


	#	on,,,any,24.111.67.53:UPLINK:main,,,192.168.14.2,,DNAT,CCREADER on 24.111.67.53,,ALLOW
	
	#	enabled			on
	#	proto			all # EMPTY proto ASSUME 'all'
	#	src_dev			
	#	src_ip			any # any ASSUME '0/0'
	#	dst_dev			24.111.67.53:UPLINK:main
	#	dst_ip			
	#	dst_port		all	# EMPTY dst_port ASSUME 'all'
	#	target_ip		192.168.14.2
	#	target_port		
	#	nat_target		DNAT
	#	remark			CCREADER on 53
	#	log				
	#	filter_target	ALLOW
	#	random			
	
	#	iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.53 -j DNAT --to-destination 192.168.14.2
	#	iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.14.2 -j ALLOW

=pod
iptables -t nat -F PORTFW
iptables -F PORTFWACCESS
iptables -t nat -F POSTPORTFW
iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.51 -j DNAT -p tcp --dport 80 --to-destination 192.168.19.14:80 
iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.14 -p tcp --dport 80 -j ALLOW
iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.51 -j DNAT -p tcp --dport 443 --to-destination 192.168.19.14:443 
iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.14 -p tcp --dport 443 -j ALLOW
iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p tcp --dport 80 --to-destination 192.168.19.46
iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p tcp --dport 80 -j ALLOW
iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p udp --dport 80 --to-destination 192.168.19.46
iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p udp --dport 80 -j ALLOW
iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p tcp --dport 443 --to-destination 192.168.19.46
iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p tcp --dport 443 -j ALLOW
iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.54 -j DNAT -p udp --dport 443 --to-destination 192.168.19.46
iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.19.46 -p udp --dport 443 -j ALLOW
iptables -t nat -A PORTFW -s 0/0 -d 24.111.67.53 -j DNAT --to-destination 192.168.14.2
iptables -t filter -A PORTFWACCESS -s 0/0 -d 192.168.14.2 -j ALLOW
=cut

# Configuration paths
$reload_flag = "/razwall/config/snat/needreload"; # Path to the reload flag
$config_file = '/razwall/config/snat/config';
$output_file = '/razwall/firewall/snat/iptablesdnat';

print "Processing config...\n";

# Initialize rules
push(@rules, "iptables -t nat -F PORTFW");
push(@rules, "iptables -F PORTFWACCESS");
push(@rules, "iptables -t nat -F POSTPORTFW");

open my $fh, '<', $config_file or die "Failed to open $config_file: $!";
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*$/ || $line =~ /^#/; # Skip empty lines and comments

    # Parse configuration line
    my ($enable, $proto, $src_dev, $src_ip, $dst_dev, $dst_ip, $dst_port, $target_ip, $target_port, $nat_target, $remark, $log, $filter_target, @random) = split(/,/, $line);

    next unless $enable eq 'on'; # Skip if rule is not enabled

    # Handle default and missing values
    $src_ip = ($src_ip && $src_ip ne 'any') ? $src_ip : '0/0';
    $dst_ip ||= ($dst_dev =~ s/:.*$//r || '0/0');
    $target_ip ||= $dst_ip;
    $dst_port ||= '';
    $target_port ||= $dst_port;

    # Default NAT and filter targets
    $nat_target ||= 'DNAT'; 
    $filter_target ||= 'ALLOW';

    # Split protocols and ports
    my @protocols = split(/\&/, $proto || 'all');
    my @dst_ports = $dst_port ? split(/\&/, $dst_port) : ('all');
    my @target_ports = $target_port ? split(/\&/, $target_port) : @dst_ports;

    # Generate rules
    foreach my $pro (@protocols) {
        for (my $i = 0; $i < @dst_ports; $i++) {
            my $dport = $dst_ports[$i];
            my $tport = $target_ports[$i] || $dport;

            # Skip invalid combinations
            next if $dport eq 'all' && $pro eq 'all';

            # NAT rule
            my $cmd1 = "iptables -t nat -A PORTFW -s $src_ip -d $dst_ip -j $nat_target";
            if ($dport ne '') {
                $cmd1 .= " -p $pro --dport $dport --to-destination $target_ip";
                $cmd1 .= ":$tport";# if $tport ne $dport;
            } else {
                $cmd1 .= " --to-destination $target_ip";
            }
            push @rules, $cmd1;

            # Filter rule
            my $cmd2 = "iptables -t filter -A PORTFWACCESS -s $src_ip -d $target_ip -p $pro";
            $cmd2 .= " --dport $dport" if $dport ne 'all';
            $cmd2 .= " -j $filter_target";
            push @rules, $cmd2;
        }
    }
}
close $fh;

# Save rules to output file
print "Saving rules to $output_file...\n";
open my $fh2, '>', $output_file or die "Failed to open $output_file: $!";
print $fh2 "$_\n" for @rules;
close $fh2;

print "Rules generated and saved successfully.\n";

#unlink $reload_flag or warn "Could not remove $reload_flag: $!";
