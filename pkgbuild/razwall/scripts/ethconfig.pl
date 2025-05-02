#!/usr/bin/env perl
use strict;
use warnings;
use JSON;
use File::Which;

# locate required tools
my $ETHTOOL = which('ethtool')  or die "ERROR: ethtool not found in PATH\n";
my $UDEVADM  = which('udevadm') or die "ERROR: udevadm not found in PATH\n";

# 1) parse /proc/net/dev to build a list of ifaces
sub list_proc_ifaces {
    open my $fh, '<', '/proc/net/dev' or die "Cannot open /proc/net/dev: $!";
    my @ifs;
    while (<$fh>) {
        next unless /^\s*([^:]+):/;
        my $if = $1;
        next if $if eq 'lo';      # skip loopback
			 # ALLOW VLANS!
             # or $if =~ /\./;     # skip VLAN children 
        push(@ifs, $if);
    }
    close $fh;
    return @ifs;
}

# 2) ethtool -i to grab driver, version, firmware, bus-info
sub get_ethtool_info {
    my $if = shift;
    open my $fh, '-|', "$ETHTOOL -i $if 2>/dev/null" or return {};
    my %info;
    while (<$fh>) {
        chomp;
        if (/^(\w+):\s*(.+)$/) {
            $info{$1} = $2;
        }
    }
    close $fh;
    return \%info;
}

# 3) udevadm for a friendly name
sub get_udev_name {
    my $if = shift;
    open my $fh, '-|', "$UDEVADM info --query=property --name=$if 2>/dev/null" or return '';
    my ($vd, $md);
    while (<$fh>) {
        chomp;
        $vd = $1 if /^ID_VENDOR_FROM_DATABASE=(.+)/;
        $md = $1 if /^ID_MODEL_FROM_DATABASE=(.+)/;
    }
    close $fh;
    return $vd && $md ? "$vd $md" : ($md // $vd // 'Unknown Network Interface Card');
}

# 4) read MAC address from sysfs
sub get_mac {
    my $if = shift;
    if (open my $fh, '<', "/sys/class/net/$if/address") {
        chomp(my $mac = <$fh>);
        close $fh;
        return $mac;
    }
    return '';
}

# Assemble JSON array
my @result;
for my $if (list_proc_ifaces()) {
    my $et = get_ethtool_info($if);

    push @result, {
        iface    => $if,
        name     => get_udev_name($if),
        firmware => ($et->{'firmware-version'} // '') =~ s/\s+$//r,
        driver   => ($et->{driver}           // '') =~ s/\s+$//r,
        label    => '',
        mac      => get_mac($if),
        version  => ($et->{version}          // '') =~ s/\s+$//r,
        businfo  => ($et->{'bus-info'}        // '') =~ s/\s+$//r,
    };
}

# Print exactly the array you asked for
print to_json(\@result, { pretty => 1, utf8 => 1 }), "\n";
