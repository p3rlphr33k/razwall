#!/usr/bin/perl -W
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
use JSON;
use Time::HiRes qw(gettimeofday);

# Process input parameters
my $in = "";
if ($ENV{'REQUEST_METHOD'} eq 'GET') {
    $in = $ENV{'QUERY_STRING'};
}
if ($ENV{'REQUEST_METHOD'} eq 'POST') {
    $in = <STDIN>;
}
my @in = split(/&/, $in);
my %params;
foreach (@in) {
    my ($k, $v) = split(/=/, $_);
    $k =~ tr/+/ /;
    $k =~ s/%([a-fA-F0-9]{2})/pack("C", hex($1))/eg;
    $v =~ tr/+/ /;
    $v =~ s/%([a-fA-F0-9]{2})/pack("C", hex($1))/eg;
    $params{$k} = $v;
}
my $plugin = $params{'plugin'} || "";

print "Content-Type: application/json\n\n";

# ---------------- Hardware Plugin ----------------
sub get_hardware_data {
    my %data;
    $data{'cached'} = JSON::false;
    # Current time with fractional seconds
    my ($sec, $usec) = gettimeofday();
    $data{'time'} = $sec + $usec/1e6;
    
    # Get memory info from /proc/meminfo
    open my $fh, '<', '/proc/meminfo' or die "Cannot open /proc/meminfo: $!";
    my %mem;
    while (<$fh>) {
        if (/^(\w+):\s+(\d+)/) {
            $mem{$1} = $2;
        }
    }
    close $fh;
    # Memory in MB
    my $total_mem = $mem{'MemTotal'} / 1024;
    my $free_mem  = $mem{'MemFree'} / 1024;
    my $used_mem  = $total_mem - $free_mem;
    my $mem_usage = $total_mem ? int(($used_mem/$total_mem)*100) : 0;
    
    # Swap info
    my $total_swap = $mem{'SwapTotal'} / 1024;
    my $free_swap  = $mem{'SwapFree'} / 1024;
    my $used_swap  = $total_swap ? $total_swap - $free_swap : 0;
    my $swap_usage = $total_swap ? int(($used_swap/$total_swap)*100) : 0;
    
    # Get disk usage using df -h; we match by mount points
    my %disks;
    open my $df, '-|', 'df -h' or die "Cannot run df: $!";
    while (<$df>) {
        chomp;
        next if /^Filesystem/;
        my @fields = split;
        my $mount = $fields[5];
        if ($mount eq "/" || $mount eq "/var" || $mount eq "/var/efw" || $mount eq "/var/log") {
            # Remove the '%' from the usage value
            (my $use_pct = $fields[4]) =~ s/%//;
            $disks{$mount} = { total => $fields[1], use => $use_pct };
        }
    }
    close $df;
    
    my @storage;
    push @storage, {
        "USAGE" => "$mem_usage",
        "TOTAL" => sprintf("%.0f MB", $total_mem),
        "NAME"  => "Memory",
        "KEY"   => "memory"
    };
    push @storage, {
        "USAGE" => "$swap_usage",
        "TOTAL" => sprintf("%.0f MB", $total_swap),
        "NAME"  => "Swap",
        "KEY"   => "swap"
    };
    if (exists $disks{'/'}) {
        push @storage, {
            "USAGE" => $disks{'/'}{use},
            "TOTAL" => $disks{'/'}{total},
            "NAME"  => "Main disk",
            "KEY"   => "df-root"
        };
    }
    if (exists $disks{'/var'}) {
        push @storage, {
            "USAGE" => $disks{'/var'}{use},
            "TOTAL" => $disks{'/var'}{total},
            "NAME"  => "Data disk",
            "KEY"   => "df-var"
        };
    }
    if (exists $disks{'/var/efw'}) {
        push @storage, {
            "USAGE" => $disks{'/var/efw'}{use},
            "TOTAL" => $disks{'/var/efw'}{total},
            "NAME"  => "Configuration disk",
            "KEY"   => "df-var/efw"
        };
    }
    if (exists $disks{'/var/log'}) {
        push @storage, {
            "USAGE" => $disks{'/var/log'}{use},
            "TOTAL" => $disks{'/var/log'}{total},
            "NAME"  => "Log disk",
            "KEY"   => "df-var/log"
        };
    }
    $data{'storage'} = \@storage;
    
    # Get CPU statistics from /proc/stat
    open my $cpu_fh, '<', '/proc/stat' or die "Cannot open /proc/stat: $!";
    my %cpustat;
    my $global_line;
    my @core_lines;
    while (<$cpu_fh>) {
        if (/^cpu\s+/) {
            $global_line = $_;
        } elsif (/^cpu\d+/) {
            push @core_lines, $_;
        }
    }
    close $cpu_fh;
    
    my @global_vals = split ' ', $global_line;
    shift @global_vals;  # remove "cpu"
    my ($g_user, $g_nice, $g_system, $g_idle) = @global_vals[0..3];
    my $g_total = 0; $g_total += $_ for @global_vals;
    $cpustat{'global'} = {
        "system" => $g_system+0,
        "cpu_id" => "global",
        "idle"   => $g_idle+0,
        "user"   => $g_user+0,
        "total"  => $g_total+0,
        "nice"   => $g_nice+0
    };
    
    foreach my $line (@core_lines) {
        my @vals = split ' ', $line;
        my $cpu_id = shift @vals;
        $cpu_id =~ s/cpu//;
        my ($user, $nice, $system, $idle) = @vals[0..3];
        my $total = 0; $total += $_ for @vals;
        $cpustat{"$cpu_id"} = {
            "system" => $system+0,
            "cpu_id" => "$cpu_id",
            "idle"   => $idle+0,
            "user"   => $user+0,
            "total"  => $total+0,
            "nice"   => $nice+0
        };
    }
    $data{'cpustat'} = \%cpustat;
    
    return \%data;
}

# ---------------- Uplinks Plugin ----------------
# Helper functions for network data:
sub get_ip {
    my $iface = shift;
    my $ip = "0.0.0.0";
    my $output = `ip addr show $iface 2>/dev/null`;
    if ($output =~ /inet (\d+\.\d+\.\d+\.\d+)/) {
        $ip = $1;
    }
    return $ip;
}

sub get_gateway {
    my $iface = shift;
    my $gw = "";
    my $route = `ip route show default 2>/dev/null`;
    if ($route =~ /default via (\d+\.\d+\.\d+\.\d+).*dev $iface/) {
        $gw = $1;
    }
    return $gw;
}

sub get_interface_uptime {
    my $iface = shift;
    # For simplicity, we use system uptime as a proxy for interface uptime
    open my $fh, '<', '/proc/uptime' or return "0";
    my $line = <$fh>;
    close $fh;
    my ($uptime) = split ' ', $line;
    return sprintf("%.0f", $uptime);
}

sub get_uplinks_data {
    my %data;
    my $time = time();
    $data{'cacheHitAt'} = $time - 10;
    $data{'cachedOn'} = $time - 11;
    $data{'time'} = $time;
    
    my @uplinks;
    # First uplink (assume eth1)
    my %network;
    $network{'WAN_DEV'}  = "eth1";
    $network{'WAN_ADDR'} = get_ip("eth1");
    $network{'WAN_TYPE'} = "DHCP";
    $network{'WAN_GW'}   = get_gateway("eth1");
    my $wan_uptime = get_interface_uptime("eth1");
    push @uplinks, {
        "status" => "ACTIVE",
        "defaultGatewayTimestamp" => $time - 1000,
        "managed" => "on",
        "shouldBeUp" => JSON::true,
        "canStart" => JSON::true,
        "isLinkAlive" => JSON::true,
        "data" => {
            "name" => $network{'WAN_DEV'},
            "ip" => $network{'WAN_ADDR'},
            "last_retry" => "",
            "interface" => $network{'WAN_DEV'},
            "type" => $network{'WAN_TYPE'},
            "gateway" => $network{'WAN_GW'}
        },
        "defaultGateway" => JSON::true,
        "uptime" => $wan_uptime,
        "name" => "main",
        "isLinkActive" => JSON::true,
        "enabled" => "on",
        "autostart" => "on",
        "hasChanged" => JSON::true
    };
    
  
    $data{'uplinks'} = \@uplinks;
    $data{'cached'} = JSON::false;
    return \%data;
}

# ---------------- Service Plugin ----------------
sub get_service_data {
    my %data;
    my $time = time();
    $data{'cached'} = JSON::true;
    $data{'cachedOn'} = $time - 10;
    $data{'cacheHitAt'} = $time - 5;
    $data{'time'} = $time;
    $data{'tail-smtp/connections-virus'} = {"value" => 0.0};
    $data{'tail-smtp/connections-spam'}  = {"value" => 0.0};
    $data{'tail-pop/connections-virus'}   = {"value" => 0.0};
    $data{'tail-smtp/connections-noqueue'} = {"value" => 0.0};
    $data{'tail-http/connections-denied'}   = {};
    $data{'tail-pop/connections-scanned'}   = {"value" => 0.0};
    $data{'tail-smtp/connections-clean'}     = {"value" => 0.0};
    $data{'tail-smtp/connections-incoming'}  = {"value" => 0.0};
    
    # Get memory used (approximate) from /proc/meminfo
    open my $fh, '<', '/proc/meminfo' or die "Cannot open /proc/meminfo: $!";
    my %mem;
    while (<$fh>) {
        if (/^(\w+):\s+(\d+)/) {
            $mem{$1} = $2;
        }
    }
    close $fh;
    my $mem_used = $mem{'MemTotal'} - $mem{'MemFree'};
    $data{'memory/memory-used'} = {"value" => $mem_used * 1024};
    
    $data{'tail-http/connections-hit'}  = {};
    $data{'tail-http/connections-miss'} = {};
    $data{'tail-pop/connections-spam'}  = {"value" => 0.0};
    $data{'tail-http/connections-virus'} = {};
    $data{'filecount-postfix_queue/files'} = {"value" => 0.0};
    $data{'tail-smtp/connections-sent'} = {"value" => 0.0};
    return \%data;
}

# ---------------- Network Plugin ----------------
sub get_network_data {
    my %data;
    $data{'cached'} = JSON::false;
    # Read /proc/net/dev for interface statistics
    my %ifaces;
    open my $fh, '<', '/proc/net/dev' or die "Cannot open /proc/net/dev: $!";
    while (<$fh>) {
        chomp;
        if (/^\s*([^:]+):\s*(.+)$/) {
            my $iface = $1;
            my $stats = $2;
            my @values = split(/\s+/, $stats);
            # rx bytes is first, tx bytes is ninth
            $ifaces{$iface} = { rx => $values[0] + 0, tx => $values[8] + 0 };
        }
    }
    close $fh;
    
    # Build "collectd" section with keys like "netlink-<iface>/if_octets"
    my %collectd;
    foreach my $iface (keys %ifaces) {
        $collectd{"netlink-$iface/if_octets"} = {
            rx => $ifaces{$iface}{rx},
            tx => $ifaces{$iface}{tx}
        };
    }
    $data{'interfaces'}{'collectd'} = \%collectd;
    
    # Build "devices" section with status from /sys/class/net
    my %devices;
    foreach my $iface (keys %ifaces) {
        my $status = "Down";
        if (open my $fh, '<', "/sys/class/net/$iface/operstate") {
            chomp(my $state = <$fh>);
            close $fh;
            $status = ($state eq "up") ? "Up" : "Down";
        }
        my $is_bridge = (-e "/sys/class/net/$iface/bridge") ? JSON::true : JSON::false;
        $devices{$iface} = {
            "STATUS"  => $status,
            "BRIDGE"  => ($is_bridge ? JSON::true : JSON::false),
            "CHECKED" => ($status eq "Up" ? "checked" : ""),
            "CLASS"   => ($status eq "Up" ? "green" : "red"),
            "LINK"    => $status,
            "IN"      => "",
            "DEVICE"  => $iface,
            "TYPE"    => "ethernet",
            "DISPLAY" => $iface,
            "OUT"     => ""
        };
        if ($is_bridge) {
            opendir my $dir, "/sys/class/net/$iface/brif";
            my @phys = grep { /^[^.]/ } readdir $dir;
            closedir $dir;
            my @physical;
            foreach my $p (@phys) {
                push @physical, {
                    "STATUS"  => "Up",
                    "CHECKED" => "",
                    "LINK"    => "Up",
                    "IN"      => "",
                    "DEVICE"  => $p,
                    "TYPE"    => "ethernet",
                    "DISPLAY" => $p,
                    "OUT"     => ""
                };
            }
            $devices{$iface}{"PHYSICAL"} = \@physical;
        }
    }
    $data{'interfaces'}{'devices'} = \%devices;
    $data{'names'} = ["collectd", "devices"];
    $data{'time'} = time();
    return \%data;
}

# ---------------- System Plugin ----------------
sub get_system_data {
    my %data;
    $data{'cached'} = JSON::false;
    $data{'time'} = time();
    $data{'appliance'} = "RazWall";
    $data{'version'} = "1.0.0";
    chomp(my $kernel_value = `uname -r`);
    $data{'kernel_value'} = $kernel_value;
    $data{'kernel'} = 0;
    open my $fh, '<', '/proc/uptime' or die "Cannot open /proc/uptime: $!";
    my $uptime_line = <$fh>;
    close $fh;
    my ($uptime) = split ' ', $uptime_line;
    my $days = int($uptime/86400);
    my $hours = int(($uptime % 86400)/3600);
    my $minutes = int((($uptime % 86400) % 3600)/60);
    $data{'uptime'} = "${days}d ${hours}h ${minutes}m";
    return \%data;
}

# ---------------- Signatures Plugin ----------------
sub get_signatures_data {
    my %data;
    $data{'cached'} = JSON::false;
    $data{'time'} = time();
    $data{'signatures'} = {
        "Urlfilter blacklist" => "N/A",
        "Anti-spyware lists"  => "N/A"
    };
    $data{'no_signatures_msg'} = "No recent signature updates found";
    return \%data;
}

if ($plugin eq "hardware") {
    my $hardware = get_hardware_data();
    print to_json($hardware, { pretty => 1 });
}
if ($plugin eq "uplinks") {
    my $uplinks = get_uplinks_data();
    print to_json($uplinks, { pretty => 1 });
}
if ($plugin eq "service") {
    my $service = get_service_data();
    print to_json($service, { pretty => 1 });
}
if ($plugin eq "network") {
    my $network = get_network_data();
    print to_json($network, { pretty => 1 });
}
if ($plugin eq "system") {
    my $system = get_system_data();
    print to_json($system, { pretty => 1 });
}
if ($plugin eq "signatures") {
    my $signatures = get_signatures_data();
    print to_json($signatures, { pretty => 1 });
}
