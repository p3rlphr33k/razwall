#!/usr/bin/perl
use strict;
use warnings;
use JSON;

my $iptables  = '/sbin/iptables';
my $ip6tables = '/sbin/ip6tables';

sub read_file {
    my ($file) = @_;
    open my $fh, '<', $file or return;
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

sub load_json {
    my ($file) = @_;
    my $text = read_file($file) or return [];
    return decode_json($text);
}

my $settings     = load_json('settings.json');
my $flush        = $settings->{flush}        // 1;
my $preview      = $settings->{preview}      // 0;
my $log_enabled  = $settings->{log_enabled}  // 1;
my $use_ipv6     = $settings->{enable_ipv6}  // 0;
my $show_stats   = $settings->{show_stats}   // 1;

sub run_cmd {
    my ($cmd) = @_;
    print "[CMD] $cmd\n";
    system($cmd) unless $preview;
}

sub flush_all {
    return unless $flush;
    for my $bin ($iptables, ($use_ipv6 ? $ip6tables : ())) {
        run_cmd("$bin -F");
        run_cmd("$bin -t nat -F");
        run_cmd("$bin -X");
        run_cmd("$bin -t nat -X");
    }
}

sub expand_array {
    my ($val) = @_;
    return () unless defined $val;
    return ref($val) eq 'ARRAY' ? @$val : ($val);
}

sub build_rule {
    my ($bin, $table, $chain, $rule, $tag_prefix) = @_;
    return if defined($rule->{enable}) && !$rule->{enable};

    my @sources = expand_array($rule->{source} // 'ANY');
    my @dests   = expand_array($rule->{destination} // 'ANY');

    foreach my $src (@sources) {
        foreach my $dst (@dests) {
            my @cmd = ($bin);
            push @cmd, ('-t', $table) if $table;
            push @cmd, ('-A', $chain);

            push @cmd, ('-i', $rule->{interface}) if $rule->{interface};
            push @cmd, ('-o', $rule->{out_interface}) if $rule->{out_interface};
            push @cmd, ('-s', $src) if $src ne 'ANY';
            push @cmd, ('-d', $dst) if $dst ne 'ANY';

            unless (uc($rule->{proto} // '') eq 'ALL') {
                push @cmd, ('-p', $rule->{proto}) if $rule->{proto};
                push @cmd, ('--dport', $rule->{port}) if $rule->{port} && uc($rule->{port}) ne 'ALL';
                push @cmd, ('--sport', $rule->{sport}) if $rule->{sport} && uc($rule->{sport}) ne 'ALL';
            }

            push @cmd, ('-m', 'state', '--state', $rule->{state}) if $rule->{state};
            push @cmd, ('-j', $rule->{action} || 'ACCEPT');

            run_cmd(join(' ', @cmd));

            if ($log_enabled && $rule->{log}) {
                my @logcmd = @cmd;
                pop @logcmd for 1 .. 2;  # remove old -j ACTION
                push @logcmd, (
                    '-j', 'LOG',
                    '--log-prefix', "\"FW:$tag_prefix\"",
                    '--log-level', 4
                );
                run_cmd(join(' ', @logcmd));
            }
        }
    }
}

sub apply_table {
    my ($file, $table, $chain, $is_nat) = @_;
    my $rules = load_json($file);
    foreach my $r (@$rules) {
        next unless ref $r eq 'HASH' || ref $r eq 'ARRAY';
        if (ref $r eq 'HASH') {
            my $bins = choose_bins($r->{ip_version});
            foreach my $bin (@$bins) {
                build_rule($bin, $table, $chain, $r, $r->{tag} // "$chain");
            }
        }
        elsif (ref $r eq 'ARRAY') {
            foreach my $zone (@$r) {
                foreach my $rule (@{$zone->{rules}}) {
                    my $bins = choose_bins($rule->{ip_version});
                    foreach my $bin (@$bins) {
                        build_rule($bin, $table, $chain, $rule, $rule->{tag} // "$zone->{interface}_$rule->{port}");
                    }
                }
            }
        }
    }
}

sub choose_bins {
    my ($ver) = @_;
    return [$iptables, $ip6tables] if defined($ver) && $ver eq 'both';
    return [$ip6tables] if defined($ver) && $ver eq '6';
    return [$iptables];  # default to IPv4
}

sub show_iptables_stats {
    return unless $show_stats && !$preview;
    print "\n[IPTABLES STATS]\n";
    run_cmd("$iptables -v -n -L");
    run_cmd("$iptables -t nat -v -n -L");
    if ($use_ipv6) {
        run_cmd("$ip6tables -v -n -L");
        run_cmd("$ip6tables -t nat -v -n -L");
    }
}

# MAIN
flush_all();
apply_table('snat.json', 'nat', 'POSTROUTING', 1);
apply_table('dnat.json', 'nat', 'PREROUTING', 1);
apply_table('outbound.json', '', 'FORWARD', 0);
apply_table('vpn.json', '', 'FORWARD', 0);
apply_table('zones.json', '', 'FORWARD', 0);

show_iptables_stats();
print "[DONE] Firewall rules applied.\n" unless $preview;
