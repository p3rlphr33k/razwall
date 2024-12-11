#!/usr/bin/perl
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
#
# $Id: graphs.cgi,v 1.9.2.1 2004/05/15 22:04:15 gespinasse Exp $
#

require 'header.pl';

my %cgiparams;
my %pppsettings;
my (@cgigraphs, @graphs);

&showhttpheaders();

$ENV{'QUERY_STRING'} =~ s/&//g;
my @cgigraphs = split(/graph=/,$ENV{'QUERY_STRING'});

# Added for conversion of utf-8 characters
use Encode 'from_to';

my $loadingImg  = '/toscawidgets/resources/static/images/loading.gif';

my %strings_period = (
    'day' => _('Day'),
    'week' => _('Week'),
    'month' => _('Month'),
    'year' => _('Year')
);
my %strings_zone = (
    'LAN' => _('LAN'),
    'DMZ' => _('DMZ'),
    'LAN2' => _('LAN2'),
    'WAN' => _('WAN')
);

my %graphtitles = (
    'LAN' => _('LAN Graph'),
    'LAN2' => _('LAN2 Graph'),
    'DMZ' => _('DMZ Graph'),
    'WAN' => _('WAN Graph'),
    'cpu' => _('CPU Graph'),
    'memory' => _('Memory Graph'),
    'swap' => _('Swap Graph'),
    'disk' => _('Disk Graph'),
    'df' => _('Disk Usage'),
    'proxy' => _('Proxy Graph'),
    'proxy_if_octets' => 'Proxy Graph: Total traffic',
    'proxy_http_requests' => 'Proxy Graph: Total accesses',
    'proxy_cache_result' => 'Proxy Graph: Cache hits',
    'proxy_cache_ratio' => 'Proxy Graph: Cache hits ratio over 5 minutes',
); 

my %imgtitles = (
    'LAN' => 'Traffic on LAN per %s',
    'LAN2' => 'Traffic on LAN2 per %s',
    'DMZ' => 'Traffic on DMZ per %s',
    'WAN' => 'Traffic on WAN per %s',
    'cpu' => 'CPU Usage per %s',
    'memory' => 'Memory usage per %s',
    'swap' => 'Swap usage per %s',
    'disk' => 'Disk access per %s',
    'df' => 'Disk usage per %s',
    'proxy_if_octets' => 'Proxy Graph: Total traffic per %s',
    'proxy_http_requests' => 'Proxy Graph: Total accesses per %s',
    'proxy_cache_result' => 'Proxy Graph: Cache hits per %s',
    'proxy_cache_ratio' => 'Proxy Graph: Cache hits ratio over 5 minutes per %s',
);

my %partition_names = (
    '/' => _('Main disk'),
    '/var' => _('Data disk'),
    '/var/efw' => _('Configuration disk'),
    '/var/log' => _('Log disk'),
    '/boot' => _('Boot disk'),
    '/mnt/usbstick' => _('Backup disk'),
    '/tmp' => _('Temp')
);


my $UUID_FILE = '/etc/uuid';


sub getUUID {
	my $content = '';
	open(FILE, $UUID_FILE);
	$content = <FILE>;
	close(FILE);
	return $content;
}


sub getDFPartitions {
        my $dir = "/tmp/collectd/rrd/" . getUUID() . "/df/df-*.rrd";
        my @partitions = ();
        my @files = glob $dir;
        foreach $file (@files) {
                $file =~ /\/df-(.*)\.rrd$/;
                push (@partitions, $1);
        }       
        return @partitions;
}


sub getPartitionName {
	my $part = shift;
	if ($part eq 'root') {
		return $partition_names{'/'};
	}
	$part =~ s/-/\//g;
	$part = "/$part";
	return $partition_names{$part} || $part;
}


sub imgTag {
	my $title = shift;
	my $timespan = shift;
	my $plugin = shift;
	my $instance = shift;
	my $width = 584;
	my $height = 134;
	my $uuid = getUUID();
	my $type = $plugin;
	my $miscArgs = '';

	if ($plugin eq 'cpu') {
		$miscArgs = 'plugin_instance=0';
	} elsif ($plugin eq 'proxy') {
		$plugin = 'snmp';
		$type = $instance;
		$miscArgs = "type_instance=squid";
	} elsif ($plugin eq 'df') {
		$miscArgs = "type_instance=$instance";
	} elsif ($plugin eq 'netlink') {
		$type = 'if_octets';
		my $dev = '';
		if ($instance =~ /WAN_/) {
			my %config = ();
			my $red;
			my $uplink;
			($red, $uplink) = split('_', $instance, 2);
			&readhash("/var/efw/uplinks/$uplink/settings", \%config);
			$dev = $config{'WAN_DEV'};
		} else {
			$dev = $ethsettings{$instance.'_DEV'}
		}
		$miscArgs = 'plugin_instance=' . $dev;
	}
	my $randID = int(rand(10000));
	$randID = "graph_${plugin}_${instance}_$randID";
	if ($miscArgs) {
		$miscArgs = ';' . $miscArgs;
	}
	my $srcAttr = "/cgi-bin/collection.cgi?action=show_graph;plugin=$plugin;type=$type;timespan=$timespan;host=$uuid;title=$title;width=$width;height=$height$miscArgs";
	my $jsscript = "<script>\$(function () { var img = new Image(); \$(img).load(function () {\$(this).hide();\$('#$randID').css('background-image', 'none').height('auto').append(this);\$(this).fadeIn();}).error(function () {}).attr('src', '$srcAttr'); });</script>";
	my $tmpl = "<div id=\"$randID\" style=\"background: url('$loadingImg') no-repeat center center;height: 40px;\"></div>$jsscript";
	return $tmpl;
}


if ($cgigraphs[1] =~ /(network|LANN|LAN2|DMZ|WAN)/) {
	&openpage(_('Network traffic graphs'), 1, '');
} else {
	&openpage(_('System graphs'), 1, '');
}
&openbigbox($errormessage, $warnmessage, $notemessage);
if ($cgigraphs[1] =~ /(LAN|LAN2|DMZ|WAN|cpu|memory|swap|disk|df|proxy_)/) {
	$graph = $cgigraphs[1];
	my $plugin = $graph;
	my $instance = '';
	if ($graph =~ /(LAN|LAN2|DMZ|WAN)/) {
		$plugin = 'netlink';
		$instance = $graph;
	} elsif ($graph =~ /proxy_(.*)/) {
		$instance = $1;
		$plugin = 'proxy';
	} elsif ($graph =~ /df_(.*)/) {
		$instance = $1;
		$graph = 'df';
		$plugin = 'df';
	}
	&openbox('100%', 'center', $graphtitles{$cgigraphs[1]});

	for my $timespan (qw(day week month year)) {
		my $title = '';
		if ($instance =~ /WAN_(.*)/) {
			my $uplink = $1;
			$title = _("Traffic on %s", $strings_zone{'RED'}) . " ($uplink) (" . _('Graph per %s', $strings_period{$timespan}) . ")";
		} elsif ($graph eq 'df') {
			my $part_name = getPartitionName($instance);
			$title = _('Disk usage') . ": $part_name (" . _('Graph per %s', $strings_period{$timespan}) . ")";
		} elsif ($instance =~ /(LAN|LAN2|DMZ)/) {
			$title = _('Traffic on %s', $strings_zone{$graph}) . " (" . _('Graph per %s', $strings_period{$timespan}) . ")";
		} else {
			$title = _($imgtitles{$graph}, $strings_period{$timespan});
		}
		print <<EOF
		<hr />
EOF
,imgTag($title, $timespan, $plugin, $instance);
	}
	&closebox();
	print "<div align='center'><table width='80%'><tr><td align='center'>";
	if ($cgigraphs[1] =~ /(LAN|LAN2|DMZ|WAN)/) {
		print "<a href='/cgi-bin/graphs.cgi?graph=network'>";
	} else {
		print "<a href='/cgi-bin/graphs.cgi'>";
	}
	print _('BACK') ."</a></td></tr></table></div>\n";
	;
} elsif ($cgigraphs[1] =~ /network/) {
	push (@graphs, ('LAN'));
	if (blue_used()) {
		push (@graphs, ('LAN2')); }
	if (orange_used()) {
		push (@graphs, ('DMZ')); }

	$uplinks = get_uplinks();
	foreach my $ul (@$uplinks) {
	    push (@graphs, ("WAN_".$ul));
	}

	foreach $graphname (@graphs) {
		my $title = '';
		if ($graphname =~ /WAN_(.*)/) {
			my $uplink = $1;
			&openbox('100%', 'center', _("WAN graph of uplink %s", $uplink));
			$title = _("Traffic on %s", $strings_zone{'WAN'}) . " ($uplink) (" . _('Graph per %s', $strings_period{'day'}) . ")";
		} else {
			&openbox('100%', 'center', $graphtitles{$graphname});
			$title = _('Traffic on %s', $strings_zone{$graphname}) . " (" . _('Graph per %s', $strings_period{'day'}) . ")";
		}
		printf <<EOF
<a href='/cgi-bin/graphs.cgi?graph=$graphname'>
  %s
</a>
EOF
,imgTag($title, 'day', "netlink", $graphname)
;
		&closebox();
	}
} elsif ($cgigraphs[1] =~ /proxy/) {
	for my $info_type (qw(if_octets http_requests cache_result cache_ratio)) {
		my $fn = "/tmp/collectd/rrd/" . getUUID() . "/snmp/$info_type-squid.rrd";
		my $g_title = _($imgtitles{"proxy_$info_type"}, $strings_period{'day'});
		&openbox('100%', 'center', $g_title);
		if (! -e $fn) {
			print _('No information available.');
		} else {
			printf <<EOF
<a href='/cgi-bin/graphs.cgi?graph=proxy_$info_type'>%s</a>
EOF
, imgTag($g_title, 'day', "proxy", $info_type)
;
		}
		&closebox();
	}
} else {
	&openbox('100%', 'center', _('CPU graph'));
	printf <<EOF
<a href='/cgi-bin/graphs.cgi?graph=cpu'>%s</a>
EOF
,imgTag(_('CPU Usage per %s', $strings_period{'day'}), 'day', "cpu")
;
	&closebox();

	&openbox('100%', 'center', _('Memory graph'));
	printf <<EOF
<a href='/cgi-bin/graphs.cgi?graph=memory'>%s</a>
EOF
,imgTag(_('Memory usage per %s', $strings_period{"day"}), 'day', "memory")
;
	&closebox();

	&openbox('100%', 'center', _('Swap graph'));
	printf <<EOF
<a href='/cgi-bin/graphs.cgi?graph=swap'>%s</a>
EOF
, imgTag(_('Swap usage per %s', $strings_period{'day'}), 'day', "swap")
;
	&closebox();

foreach $partition (getDFPartitions()) {
		$part_name = getPartitionName($partition);
		&openbox('100%', 'center', _('Disk usage graph') . ": $part_name");
		printf <<EOF
<a href='/cgi-bin/graphs.cgi?graph=df_$partition'>%s</a>
EOF
, imgTag(_('Disk usage') . ": $part_name (" . _('Graph per %s', $strings_period{'day'}) . ")", 'day', "df", $partition);
		&closebox();
	}
}

&closebigbox();
&closepage();
