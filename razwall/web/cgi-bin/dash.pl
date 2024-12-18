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
#print "Content-Type: Text/HTML\n\n";

if ($ENV{'REQUEST_METHOD'} eq 'GET') {
      $in = $ENV{'QUERY_STRING'};
}
if ($ENV{'REQUEST_METHOD'} eq 'POST') {
	$in = <STDIN>;
}

@in = split(/&/, $in);
foreach(@in) {
	($k,$v) = split(/=/,$_);
	$k =~ tr/+/ /;
	$k =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$k =~ s/\+/ /g;
	$v =~ tr/+/ /;
	$v =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$v =~ s/\+/ /g;
	#$v =~ s///g;
	${$k} = $v;
	#print "$k = $v\n";
}

print "Content-Type: application/json\n\n";


if($plugin eq  "hardware") {
print qq~
{"cached": false, "time": 1731600469.0089741, "storage": [{"USAGE": "3", "TOTAL": "15993 MB", "NAME": "Memory", "KEY": 
"memory"}, {"USAGE": "0", "TOTAL": "15991 MB", "NAME": "Swap", "KEY": "swap"}, {"USAGE": "19", "TOTAL": "4.8G", "NAME": 
"Main disk", "KEY": "df-root"}, {"USAGE": "16", "TOTAL": "117.8G", "NAME": "Data disk", "KEY": "df-var"}, {"USAGE": "8", 
"TOTAL": "120M", "NAME": "Configuration disk", "KEY": "df-var/efw"}, {"USAGE": "5", "TOTAL": "78.5G", "NAME": "Log disk", 
"KEY": "df-var/log"}], "cpustat": {"global": {"system": 487798, "cpu_id": "global", "idle": 197231268, "user": 1720558, 
"total": 199439624, "nice": 0}, "1": {"system": 59522, "cpu_id": "1", "idle": 24677804, "user": 204225, "total": 24941551, 
"nice": 0}, "0": {"system": 58756, "cpu_id": "0", "idle": 24606690, "user": 241307, "total": 24906753, "nice": 0}, "3": 
{"system": 58025, "cpu_id": "3", "idle": 24693697, "user": 187583, "total": 24939305, "nice": 0}, "2": {"system": 60161, 
"cpu_id": "2", "idle": 24660268, "user": 205603, "total": 24926032, "nice": 0}, "5": {"system": 65200, "cpu_id": "5", 
"idle": 24647361, "user": 210924, "total": 24923485, "nice": 0}, "4": {"system": 65501, "cpu_id": "4", "idle": 24638473, 
"user": 232284, "total": 24936258, "nice": 0}, "7": {"system": 59403, "cpu_id": "7", "idle": 24656967, "user": 200100, 
"total": 24916470, "nice": 0}, "6": {"system": 61230, "cpu_id": "6", "idle": 24650008, "user": 238532, "total": 24949770, 
"nice": 0}}}
~;
}

if($plugin eq "uplinks") {
print qq~
{"cacheHitAt": 1731600455.4530821, "cachedOn": 1731600454.6696789, "time": 1731600454.66975, "uplinks": [{"status": 
"ACTIVE", "defaultGatewayTimestamp": 1731349117.8499999, "managed": "on", "shouldBeUp": true, "canStart": true, 
"isLinkAlive": true, "data": {"name": "'Main uplink'", "ip": "24.111.67.50", "last_retry": "", "interface": "eth3", "type": 
"STATIC", "gateway": "24.111.67.49"}, "defaultGateway": true, "uptime": "2d 21h 50m 14s", "name": "main", "isLinkActive": 
true, "enabled": "on", "autostart": "on", "hasChanged": true}, {"status": "ACTIVE", "defaultGatewayTimestamp": -1, 
"managed": "on", "shouldBeUp": true, "canStart": true, "isLinkAlive": true, "data": {"name": "'ITD WAN'", "ip": 
"10.236.4.253", "last_retry": "", "interface": "eth2", "type": "DHCP", "gateway": "10.236.4.1"}, "defaultGateway": false, 
"uptime": "2d 21h 49m 37s", "name": "uplink1", "isLinkActive": true, "enabled": "on", "autostart": "on", "hasChanged": 
true}], "cached": true}
~;
}

if($plugin eq "service") {
print qq~
{"cacheHitAt": 1731600439.1212721, "tail-smtp/connections-virus": {"value": 0.0}, "tail-smtp/connections-spam": {"value": 
0.0}, "tail-pop/connections-virus": {"value": 0.0}, "tail-smtp/connections-noqueue": {"value": 0.0}, 
"tail-http/connections-denied": {}, "cached": true, "tail-pop/connections-scanned": {"value": 0.0}, 
"tail-smtp/connections-clean": {"value": 0.0}, "time": 1731600436.315294, "tail-smtp/connections-incoming": {"value": 0.0}, 
"memory/memory-used": {"value": 521613300.0}, "tail-http/connections-hit": {}, "tail-http/connections-miss": {}, 
"tail-pop/connections-spam": {"value": 0.0}, "tail-http/connections-virus": {}, "cachedOn": 1731600436.315212, 
"filecount-postfix_queue/files": {"value": 0.0}, "tail-smtp/connections-sent": {"value": 0.0}}
~;
}

if($plugin eq "network") {
print qq~
{"cached": false, "interfaces": {"collectd": {"netlink-br1/if_octets": {"rx": 1614897.0, "tx": 2907912.0}, "netlink-br0/if_octets": {"rx": 101043.5, "tx": 2187896.0}, "netlink-eth3/if_octets": {"rx": 5233503.0, "tx": 1751013.0}, "netlink-eth0.600/if_octets": {"rx": 0.0, "tx": 0.0}, "netlink-eth0.1/if_octets": {"rx": 103100.10000000001, "tx": 2187875.0}, "netlink-eth1.200/if_octets": {"rx": 1616984.0, "tx": 2907913.0}, "netlink-eth1.500/if_octets": {"rx": 0.0, "tx": 4781.5600000000004}, "netlink-eth2/if_octets": {"rx": 0.0, "tx": 0.0}, "netlink-eth0.700/if_octets": {"rx": 20.399819999999998, "tx": 248.39779999999999}, "netlink-br2/if_octets": {"rx": 0.0, "tx": 0.0}}, "devices": {"eth2": {"STATUS": "Up", "BRIDGE": false, "CHECKED": "checked", "CLASS": "red", "LINK": "Up", "IN": "", "DEVICE": "eth2", "TYPE": "ethernet", "DISPLAY": "eth2", "OUT": ""}, "eth3": {"STATUS": "Up", "BRIDGE": false, "CHECKED": "checked", "CLASS": "red", "LINK": "Up", "IN": "", "DEVICE": "eth3", "TYPE": "ethernet", "DISPLAY": "eth3", "OUT": ""}, "br2": {"STATUS": "Up", "BRIDGE": true, "CHECKED": "checked", "CLASS": "blue", "LINK": "Up", "IN": "", "DEVICE": "br2", "PHYSICAL": [{"STATUS": "Up", "CHECKED": "", "LINK": "Up", "IN": "", "DEVICE": "eth0.600", "TYPE": "ethernet", "DISPLAY": "eth0_600", "OUT": ""}], "TYPE": "ethernet", "DISPLAY": "br2", "OUT": ""}, "br1": {"STATUS": "Up", "BRIDGE": true, "CHECKED": "checked", "CLASS": "orange", "LINK": "Up", "IN": "", "DEVICE": "br1", "PHYSICAL": [{"STATUS": "Up", "CHECKED": "", "LINK": "Up", "IN": "", "DEVICE": "eth1.200", "TYPE": "ethernet", "DISPLAY": "eth1_200", "OUT": ""}, {"STATUS": "Up", "CHECKED": "", "LINK": "Up", "IN": "", "DEVICE": "eth1.500", "TYPE": "ethernet", "DISPLAY": "eth1_500", "OUT": ""}], "TYPE": "ethernet", "DISPLAY": "br1", "OUT": ""}, "br0": {"STATUS": "Up", "BRIDGE": true, "CHECKED": "checked", "CLASS": "green", "LINK": "Up", "IN": "", "DEVICE": "br0", "PHYSICAL": [{"STATUS": "Up", "CHECKED": "", "LINK": "Up", "IN": "", "DEVICE": "eth0.700", "TYPE": "ethernet", "DISPLAY": "eth0_700", "OUT": ""}, {"STATUS": "Up", "CHECKED": "", "LINK": "Up", "IN": "", "DEVICE": "eth0.1", "TYPE": "ethernet", "DISPLAY": "eth0_1", "OUT": ""}], "TYPE": "ethernet", "DISPLAY": "br0", "OUT": ""}}}, "names": ["collectd", "devices"], "time": 1731969100.4881721}
~;
}

if($plugin eq "system") {
print qq~
{"kernel": 0, "uptime": "2d 21h 49m", "cached": false, "kernel_value": "4.4.145.e7.4", "": 
"", "appliance": "RazWall", "version": "1.0.0", "time": 1731600403.7565579}
~;
}

if($plugin eq "signatures") {
print qq~
{"cached": false, "signatures": {"Urlfilter blacklist": "2016.08.30 10:55", "Anti-spyware lists": "2024.11.13 12:17"}, 
"no_signatures_msg": "No recent signature updates found", "time": 1731600380.9465301}
~;
}



