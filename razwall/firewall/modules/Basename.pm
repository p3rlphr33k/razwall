package Basename;

use strict;
use warnings;

# Extracts the basename of a file
sub basename {
    my ($path, @suffixes) = @_;
    $path =~ s{.*/}{}; # Remove directory components

    if (@suffixes) {
        for my $suffix (@suffixes) {
            $path =~ s/\Q$suffix\E$// if $path =~ /\Q$suffix\E$/;
        }
    }

    return $path;
}

# Extracts the directory name of a file
sub dirname {
    my ($path) = @_;

    $path =~ s{/+$}{};   # Remove trailing slashes
    $path =~ s{[^/]+$}{}; # Remove the basename part

    return $path eq '' ? '.' : $path;
}

1;

__END__

=head1 NAME

MyFileBasename - A simple replacement for File::Basename

=head1 SYNOPSIS

  use MyFileBasename;

  my $file = '/path/to/my/file.txt';

  my $basename = MyFileBasename::basename($file); # 'file.txt'
  my $dirname  = MyFileBasename::dirname($file);  # '/path/to/my'

  # With suffix removal
  my $basename_no_suffix = MyFileBasename::basename($file, '.txt'); # 'file'

=head1 DESCRIPTION

MyFileBasename provides simple functions to extract the directory name and
basename (with optional suffix removal) from a file path.

=head1 FUNCTIONS

=over 4

=item B<basename($path, @suffixes)>

Extracts the basename (final component) from the given file path. Optionally,
removes a specified suffix or list of suffixes if they match the end of the
basename.

=item B<dirname($path)>

Extracts the directory name from the given file path. If the path does not
contain a directory component, returns '.'

=back

=head1 AUTHOR

Your Name

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
