package ConfigSimple;

use strict;
use warnings;

sub new {
    my ($class, $filename) = @_;
    my $self = {
        _filename => $filename,
        _data     => {},
    };
    bless $self, $class;

    $self->read($filename) if $filename;
    return $self;
}

sub read {
    my ($self, $filename) = @_;
    $self->{_filename} = $filename;

    open my $fh, '<', $filename or die "Cannot open file '$filename': $!";
    my $current_section = '';

    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/^\s+|\s+$//g; # Trim whitespace
        next if $line =~ /^\s*#/; # Skip comments
        next if $line eq '';       # Skip empty lines

        if ($line =~ /^\[(.+)\]$/) {
            $current_section = $1;
            $self->{_data}{$current_section} ||= {};
        } elsif ($line =~ /^(.+?)\s*=\s*(.*)$/) {
            my ($key, $value) = ($1, $2);
            $self->{_data}{$current_section}{$key} = $value;
        } else {
            die "Invalid line format: $line";
        }
    }

    close $fh;
    return 1;
}

sub vars {
    my ($self) = @_;
    my %flat_vars;

    for my $section (keys %{$self->{_data}}) {
        for my $key (keys %{$self->{_data}{$section}}) {
            $flat_vars{"$section.$key"} = $self->{_data}{$section}{$key};
        }
    }

    return %flat_vars;
}

sub save {
    my ($self, $filename) = @_;
    $filename ||= $self->{_filename};

    open my $fh, '>', $filename or die "Cannot write to file '$filename': $!";

    for my $section (sort keys %{$self->{_data}}) {
        print $fh "[$section]\n";
        for my $key (sort keys %{$self->{_data}{$section}}) {
            my $value = $self->{_data}{$section}{$key};
            print $fh "$key=$value\n";
        }
        print $fh "\n";
    }

    close $fh;
}

sub param {
    my ($self, $key, $value) = @_;

    if (defined $value) {
        my ($section, $param) = split /\./, $key, 2;
        die "Invalid key format: $key" unless defined $param;
        $self->{_data}{$section}{$param} = $value;
    } else {
        my ($section, $param) = split /\./, $key, 2;
        return unless defined $section && defined $param;
        return $self->{_data}{$section}{$param};
    }
}

sub delete {
    my ($self, $key) = @_;
    my ($section, $param) = split /\./, $key, 2;
    delete $self->{_data}{$section}{$param} if defined $self->{_data}{$section}{$param};
}

sub sections {
    my ($self) = @_;
    return keys %{$self->{_data}};
}

sub keys {
    my ($self, $section) = @_;
    return keys %{$self->{_data}{$section}};
}

1;

__END__

=head1 NAME

MyConfigSimple - A simple replacement for Config::Simple

=head1 SYNOPSIS

  use MyConfigSimple;

  # Create an instance and read from a file
  my $cfg = MyConfigSimple->new('config.ini');

  # Or create an empty instance and read later
  my $cfg = MyConfigSimple->new();
  $cfg->read('config.ini');

  # Get all configuration as a hash
  my %config = $cfg->vars();

  # Get a parameter
  my $value = $cfg->param('section.key');

  # Set a parameter
  $cfg->param('section.key', 'new_value');

  # Save changes to the file
  $cfg->save();

  # List all sections
  my @sections = $cfg->sections();

  # List all keys in a section
  my @keys = $cfg->keys('section');

  # Delete a key
  $cfg->delete('section.key');

=head1 DESCRIPTION

MyConfigSimple provides basic functionality for reading, writing, and manipulating
configuration files in the INI format. It is designed as a drop-in replacement for
Config::Simple when installing modules from CPAN is not an option.

=head1 METHODS

=over 4

=item B<new($filename)>

Creates a new instance and optionally loads a configuration file.

=item B<read($filename)>

Reads a configuration file into the object.

=item B<vars()>

Returns the entire configuration as a flat hash, with keys in the format 'section.key'.

=item B<param($key [, $value])>

Gets or sets a parameter. The key should be in the format 'section.key'.

=item B<save([$filename])>

Saves the current configuration to a file. If no filename is specified, it saves to
the file used during initialization.

=item B<delete($key)>

Deletes a parameter specified by 'section.key'.

=item B<sections()>

Returns a list of all sections in the configuration.

=item B<keys($section)>

Returns a list of all keys in the specified section.

=back

=head1 AUTHOR

Your Name

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
