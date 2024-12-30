package OptLong;

use strict;
use warnings;

sub GetOptions {
    my (%handlers) = @_;
    my @args = @ARGV;
    my %results;

    while (@args) {
        my $arg = shift @args;

        # Handle long options (e.g., --option=value or --option value)
        if ($arg =~ /^--(\w[\w\-]*)=(.*)$/) {
            my ($key, $value) = ($1, $2);
            if (exists $handlers{$key}) {
                $results{$key} = $value;
            } else {
                die "Unknown option: --$key";
            }
        } elsif ($arg =~ /^--(\w[\w\-]*)$/) {
            my $key = $1;
            if (exists $handlers{$key}) {
                if (ref $handlers{$key} eq 'SCALAR') {
                    $results{$key} = 1; # Boolean flag
                } elsif (ref $handlers{$key} eq 'ARRAY') {
                    my $value = shift @args;
                    die "Value required for option --$key" unless defined $value;
                    push @{$results{$key}}, $value;
                } else {
                    my $value = shift @args;
                    die "Value required for option --$key" unless defined $value;
                    $results{$key} = $value;
                }
            } else {
                die "Unknown option: --$key";
            }
        } elsif ($arg =~ /^-(\w)$/) { # Short options (e.g., -o)
            my $key = $1;
            if (exists $handlers{$key}) {
                if (ref $handlers{$key} eq 'SCALAR') {
                    $results{$key} = 1; # Boolean flag
                } else {
                    my $value = shift @args;
                    die "Value required for option -$key" unless defined $value;
                    $results{$key} = $value;
                }
            } else {
                die "Unknown option: -$key";
            }
        } else {
            die "Unknown argument: $arg";
        }
    }

    # Assign results to the handler references
    for my $key (keys %handlers) {
        if (exists $results{$key}) {
            if (ref $handlers{$key} eq 'SCALAR') {
                ${$handlers{$key}} = $results{$key};
            } elsif (ref $handlers{$key} eq 'ARRAY') {
                @{$handlers{$key}} = @{$results{$key}};
            }
        }
    }

    return 1;
}

1;

__END__

=head1 NAME

MyGetoptLong - A simple replacement for Getopt::Long

=head1 SYNOPSIS

  use MyGetoptLong;

  my $verbose;
  my $output;
  my @include;

  MyGetoptLong::GetOptions(
      'verbose' => \$verbose,
      'output=s' => \$output,
      'include=s@' => \@include,
  );

  print "Verbose: $verbose\n";
  print "Output: $output\n";
  print "Includes: @include\n";

=head1 DESCRIPTION

MyGetoptLong provides a simple mechanism for parsing command-line options, mimicking
the functionality of the Getopt::Long module.

=head1 METHODS

=over 4

=item B<GetOptions(%handlers)>

Parses command-line arguments and assigns values to the provided handler references.
Supports long options with --option and short options with -o.

=back

=head1 AUTHOR

Your Name

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
