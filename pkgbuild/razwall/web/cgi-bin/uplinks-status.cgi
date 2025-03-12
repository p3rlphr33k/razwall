#!/usr/bin/perl 
use strict;
use warnings;
use JSON;

my $UPLINKS_DIR = "/razwall/config/uplinks";

sub pool_info {
    opendir my $dh, $UPLINKS_DIR or die "Cannot open $UPLINKS_DIR: $!";
    my @folders = grep { -d "$UPLINKS_DIR/$_" && !/^\./ } readdir $dh;
    closedir $dh;

    my @info;
    foreach my $folder (@folders) {
        my %uplink;
        $uplink{name} = $folder;

        # Read settings file
        my $settings_file = "$UPLINKS_DIR/$folder/settings";
        if (-e $settings_file) {
            open my $fh, '<', $settings_file or die "Cannot open $settings_file: $!";
            while (<$fh>) {
                chomp;
                my ($key, $value) = split(/=/, $_, 2);
                $uplink{$key} = $value;
            }
            close $fh;
        }

        # Check for active file
        my $active_file = "$UPLINKS_DIR/$folder/active";
        if (-e $active_file) {
            $uplink{status} = "ACTIVE";
            open my $fh, '<', $active_file or die "Cannot open $active_file: $!";
            $uplink{defaultGatewayTimestamp} = <$fh>;
            chomp $uplink{defaultGatewayTimestamp};
            close $fh;
        } else {
            $uplink{status} = "INACTIVE";
            $uplink{defaultGatewayTimestamp} = -1;
        }

        # Read data file
        my $data_file = "$UPLINKS_DIR/$folder/data";
        if (-e $data_file) {
            open my $fh, '<', $data_file or die "Cannot open $data_file: $!";
            while (<$fh>) {
                chomp;
                my ($key, $value) = split(/=/, $_, 2);
                $uplink{data}{$key} = $value;
            }
            close $fh;
        }

        push @info, \%uplink;
    }

    return \@info;
}

sub list_ {
    my $cache_time = time();
    my $info = pool_info();
    my @uplinks;

    foreach my $uplink (@$info) {
        my %uplink_info = (
            status                 => $uplink->{status},
            defaultGatewayTimestamp => $uplink->{defaultGatewayTimestamp},
            managed                => $uplink->{MANAGED} // "off",
            shouldBeUp             => ($uplink->{ENABLED} && $uplink->{ENABLED} eq 'on') ? JSON::true : JSON::false,
            canStart               => JSON::true,
            isLinkAlive            => JSON::true,
            data                   => {
                name      => $uplink->{NAME} // "",
                ip        => $uplink->{WAN_ADDRESS} // "",
                last_retry => "",
                interface => $uplink->{WAN_DEV} // "",
                type      => $uplink->{WAN_TYPE} // "",
                gateway   => $uplink->{DEFAULT_GATEWAY} // "",
            },
            defaultGateway         => ($uplink->{DEFAULT_GATEWAY}) ? JSON::true : JSON::false,
            uptime                 => age($uplink->{name}),
            name                   => $uplink->{name},
            isLinkActive           => ($uplink->{status} eq 'ACTIVE') ? JSON::true : JSON::false,
            enabled                => $uplink->{ENABLED} // "off",
            autostart              => $uplink->{AUTOSTART} // "off",
            hasChanged             => JSON::true,
        );
        push @uplinks, \%uplink_info;
    }

    my %output = (
        cacheHitAt => $cache_time,
        cachedOn   => $cache_time,
        time       => $cache_time,
        uplinks    => \@uplinks,
        cached     => JSON::true,
    );

    print "Content-Type: application/json\n\n";
    print encode_json(\%output);
}

sub age {
    my ($uplink) = @_;
    my $active_file = "$UPLINKS_DIR/$uplink/active";
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

# Main Execution
list_();
