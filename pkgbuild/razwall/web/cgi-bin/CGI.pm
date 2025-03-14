package CGI;
use strict;
use warnings;
use Carp;
use URI::Escape;

our $VERSION   = '1.0';
our @EXPORT_OK = qw(header cookie param);

# Constructor: creates a new CGI object and parses the input.
sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->_parse_input();
    return $self;
}

# Internal: parse input parameters from QUERY_STRING or STDIN (for POST)
sub _parse_input {
    my ($self) = @_;
    my %params;
    my $data = '';

    # Determine request method
    if (exists $ENV{REQUEST_METHOD} && uc($ENV{REQUEST_METHOD}) eq 'POST') {
        if (defined $ENV{CONTENT_LENGTH} && $ENV{CONTENT_LENGTH} > 0) {
            read(STDIN, $data, $ENV{CONTENT_LENGTH});
        }
    }
    else {
        $data = $ENV{QUERY_STRING} || '';
    }

    # Parse the query string (or POST data)
    foreach my $pair (split /&/, $data) {
        my ($name, $value) = split /=/, $pair, 2;
        $name  = uri_unescape($name);
        $value = defined $value ? uri_unescape($value) : '';
        push @{ $params{$name} }, $value;
    }
    $self->{params} = \%params;
}

# Returns a list of parameter names if called without arguments.
# With a parameter name, returns its value (or list of values in list context).
sub param {
    my ($self, @args) = @_;

    # Allow non-object calls by creating a new object
    unless (ref $self) {
        $self = CGI->new();
    }

    if (@args) {
        my $name = $args[0];
        my $values = $self->{params}{$name} || [];
        return wantarray ? @$values : $values->[0];
    }
    else {
        return keys %{ $self->{params} };
    }
}

# Generates and returns an HTTP header string.
# Accepts named parameters similar to the original CGI header function.
# For example:
#   print CGI::header(-type=>'text/html', -charset=>'utf-8', -cookie=>$cookie);
sub header {
    my %params = @_;
    my $status  = $params{-status};
    my $type    = $params{-type}    || 'text/html';
    my $charset = $params{-charset} ? "; charset=" . $params{-charset} : '';
    my $cookie  = '';

    # Process cookies if provided
    if ($params{-cookie}) {
        my @cookies;
        if (ref $params{-cookie} eq 'ARRAY') {
            @cookies = @{$params{-cookie}};
        }
        else {
            @cookies = ($params{-cookie});
        }
        $cookie = join("\n", map { "Set-Cookie: $_" } @cookies) . "\n";
    }

    my $header = '';
    $header .= "Status: $status\n" if $status;
    $header .= "Content-Type: $type$charset\n";
    $header .= $cookie;
    $header .= "\n";
    return $header;
}

# Creates a cookie string when parameters are provided.
# When called without arguments, returns a hash of cookies from HTTP_COOKIE.
# Example usage:
#   my $cookie = CGI::cookie(-name=>'session', -value=>'ABC123', -path=>'/');
sub cookie {
    my %params = @_;
    if (%params) {
        my $name  = $params{-name}  or croak "Cookie name (-name) is required";
        my $value = defined $params{-value} ? $params{-value} : '';
        my $cookie = "$name=" . uri_escape($value);
        $cookie .= "; expires=" . $params{-expires} if $params{-expires};
        $cookie .= "; path="    . $params{-path}    if $params{-path};
        $cookie .= "; domain="  . $params{-domain}  if $params{-domain};
        $cookie .= "; secure"                    if $params{-secure};
        return $cookie;
    }
    else {
        # No parameters provided: return current cookies as a hash
        my %cookies;
        if ($ENV{HTTP_COOKIE}) {
            foreach my $pair (split /; ?/, $ENV{HTTP_COOKIE}) {
                my ($k, $v) = split /=/, $pair, 2;
                $cookies{$k} = $v;
            }
        }
        return %cookies;
    }
}

1;
