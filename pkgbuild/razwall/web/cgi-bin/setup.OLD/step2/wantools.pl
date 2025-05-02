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

require '/razwall/web/cgi-bin/netwizard_tools.pl';
require 'header.pl';

my $uplinks = 'uplinks/';
my $session = 0;
my $settings = 0;

sub init_wantools($$) {
    $session = shift;
    $settings = shift;
    $uplinks = ${swroot}.'/uplinks/';
}


sub set_wan_default($) {
    my $uplink = shift;

    if ($uplink !~ /^$/) {
	$uplink .= '_';
    }

    if (! $session->{$uplink.'ENABLED'}) {
	$session->{$uplink.'ENABLED'} = 'on';
    }
    $session->{$uplink.'WAN_TYPE'} = $session->{'WAN_TYPE'};
    if (! $session->{$uplink.'WAN_DEV'}) {
	$session->{$uplink.'WAN_DEV'} = $session->{'WAN_DEV'};
    }
    if (! $session->{$uplink.'AUTOSTART'}) {
	$session->{$uplink.'AUTOSTART'} = "on";
    }
    if (! $session->{$uplink.'ONBOOT'}) {
	$session->{$uplink.'ONBOOT'} = "on";
    }
    if (! $session->{$uplink.'MANAGED'}) {
	$session->{$uplink.'MANAGED'} = "on";
    }
}

sub load_wan($) {
    my $uplink = shift;
    $uplink = lc($uplink);
    return if ($uplink =~ /^$/);
    my %wan_settings_hash = ();
    my $wan_settings = \%wan_settings_hash;
    readhash($uplinks.$uplink.'/settings', $wan_settings);
    my @keys = keys(%$wan_settings);
    load_all_keys($session, \@keys, $wan_settings, 0, 0);
    load_all_keys($settings, \@keys, $wan_settings, 0, 0);
}

sub save_wan($$) {
    my $uplink = shift;
    my $data = shift;
    $uplink = lc($uplink);
    return if ($uplink =~ /^$/);
    writehash($uplinks.$uplink.'/settings', $data);
}

1;
