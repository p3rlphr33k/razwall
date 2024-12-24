use strict;
use warnings;
use JSON;

my $UPLINKS_DIR = "/razwall/config/uplinks";
my $ACTIVE_FILE = "$UPLINKS_DIR/%s/active";
my $uplinks_cmd = "sudo /etc/rc.d/uplinks %s %s --with-hooks";

sub pool_info {
    opendir my $dh, $UPLINKS_DIR or die "Cannot open $UPLINKS_DIR: $!";
    my @folders = grep { -d "$UPLINKS_DIR/$_" && !/^\./ } readdir $dh;
    closedir $dh;

    my @info;
    foreach my $folder (@folders) {
        my $settings_file = "$UPLINKS_DIR/$folder/settings";
        next unless -e $settings_file;

        open my $fh, '<', $settings_file or die "Cannot open $settings_file: $!";
        my %settings;
        while (<$fh>) {
            chomp;
            my ($key, $value) = split(/=/, $_, 2);
            $settings{$key} = $value;
        }
        close $fh;

        push @info, { uplinkChain => [ { name => $folder, %settings } ] };
    }

    return \@info;
}

sub list_ {
    init();
    my $info = pool_info();
    my @link_infos;

    foreach my $link (@$info) {
        my $uplink = $link->{uplinkChain}->[0];
        $uplink->{uptime} = age($uplink->{name});
        $uplink->{data} = { ip => $uplink->{RED_ADDRESS}, type => $uplink->{RED_TYPE}, gateway => $uplink->{DEFAULT_GATEWAY} };
        push @link_infos, $uplink;
    }

    print encode_json(\@link_infos);
}

sub start {
    my ($uplink) = @_;
    return unless $uplink;
    return change_status($uplink, "start");
}

sub stop {
    my ($uplink) = @_;
    return unless $uplink;
    return change_status($uplink, "stop");
}

sub change_status {
    my ($uplink, $status) = @_;
    my $cmd = sprintf($uplinks_cmd, $status, $uplink);
    my $res = system($cmd);
    return $res == 0;
}

sub to_date {
    my ($timestamp) = @_;
    return "" if $timestamp == 0;
    my @lt = localtime($timestamp);
    return sprintf("%02d:%02d:%02d", $lt[2], $lt[1], $lt[0]);
}

sub uplink_data {
    my ($up) = @_;
    return {
        ip          => $up->{RED_ADDRESS},
        type        => $up->{RED_TYPE},
        interface   => $up->{RED_DEV},
        gateway     => $up->{DEFAULT_GATEWAY},
        last_retry  => to_date($up->{failureTimestamp}),
    };
}

sub status {
    my ($uplink, $error) = @_;
    my $info = { name => $uplink };
    my $data = pool_info();
    foreach my $link (@$data) {
        if ($link->{uplinkChain}->[0]->{name} eq $uplink) {
            $info = $link->{uplinkChain}->[0];
            last;
        }
    }
    $info->{uptime} = age($uplink);
    $info->{error} = $error if $error;
    $info->{data} = uplink_data($info);

    init();
    print encode_json($info);
}

sub init {
    print "Content-type: text/html\r\n\r\n";
}

sub age {
    my ($uplink) = @_;
    my $active_file = sprintf($ACTIVE_FILE, $uplink);
    return "" unless -e $active_file;

    my $mtime = (stat($active_file))[9];
    my $now = time();
    my $unixsecs = $now - $mtime;

    my $days = int($unixsecs / 86400);
    my $totalhours = int($unixsecs / 3600);
    my $hours = $totalhours % 24;
    my $totalmins = int($unixsecs / 60);
    my $mins = $totalmins % 60;
    my $secs = $unixsecs % 60;

    return sprintf("%sd %sh %sm %ss", $days, $hours, $mins, $secs);
}

sub manage_flag {
    my ($uplink, $flag) = @_;
    my $settings_file = "$UPLINKS_DIR/$uplink/settings";
    open my $fh, "+<", $settings_file or die "Cannot open $settings_file: $!";
    my %settings;

    while (<$fh>) {
        chomp;
        my ($key, $value) = split(/=/, $_, 2);
        $settings{$key} = $value;
    }

    $settings{MANAGED} = $flag ? "on" : "off";

    seek($fh, 0, 0);
    foreach my $key (keys %settings) {
        print $fh "$key=$settings{$key}\n";
    }
    truncate($fh, tell($fh));
    close $fh;
}

sub manage {
    my ($uplink) = @_;
    manage_flag($uplink, 1);
}

sub unmanage {
    my ($uplink) = @_;
    manage_flag($uplink, 0);
}

# Main Execution
my $action = undef;
my $uplink = undef;

if (@ARGV) {
    $uplink = $ARGV[0];
    $action = $ARGV[1];
}
else {
    foreach my $arg (@ARGV) {
        if ($arg =~ /action=(.+)/) {
            $action = $1;
        } elsif ($arg =~ /uplink=(.+)/) {
            $uplink = $1;
        }
    }
}

if (!$action || $action eq "list") {
    list_();
} elsif ($action eq "start") {
    start($uplink);
} elsif ($action eq "stop") {
    stop($uplink);
} elsif ($action eq "status") {
    status($uplink);
} elsif ($action eq "manage") {
    manage($uplink);
} elsif ($action eq "unmanage") {
    unmanage($uplink);
}
