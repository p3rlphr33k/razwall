package CGI::Cookie;
use strict;
use warnings;
use Carp;
use URI::Escape;

our $VERSION = '1.0';

# Constructor: Creates a new CGI::Cookie object.
# Accepts named parameters (with or without a leading dash), for example:
#   CGI::Cookie->new(-name=>'foo', -value=>'bar', -path=>'/', -domain=>'example.com')
sub new {
    my $class = shift;
    my %args;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        %args = %{ $_[0] };
    } else {
        %args = @_;
    }

    # Support both -name and name style parameters.
    my $name = delete $args{'-name'} || delete $args{'name'};
    croak "Cookie name is required" unless defined $name;

    my $value = delete $args{'-value'} || delete $args{'value'};
    $value = '' unless defined $value;

    my $cookie = {
        name    => $name,
        value   => $value,
        domain  => delete $args{'-domain'} || delete $args{'domain'},
        path    => delete $args{'-path'}   || delete $args{'path'},
        secure  => delete $args{'-secure'} || delete $args{'secure'},
        expires => delete $args{'-expires'}|| delete $args{'expires'},
    };

    bless $cookie, $class;
    return $cookie;
}

# as_string: Returns a string representation of the cookie suitable for HTTP headers.
sub as_string {
    my $self = shift;
    my $str  = $self->{name} . "=" . uri_escape($self->{value});
    $str .= "; domain="  . $self->{domain}  if defined $self->{domain};
    $str .= "; path="    . $self->{path}    if defined $self->{path};
    $str .= "; expires=" . $self->{expires} if defined $self->{expires};
    $str .= "; secure"                     if $self->{secure};
    return $str;
}

# Accessor: Returns the cookie's name.
sub name {
    my $self = shift;
    return $self->{name};
}

# Accessor: Returns the cookie's value.
sub value {
    my $self = shift;
    return $self->{value};
}

# set: Allows modifying or setting additional cookie attributes.
# For example: $cookie->set(-path => '/', -expires => 'Wed, 09 Jun 2025 10:18:14 GMT');
sub set {
    my ($self, %args) = @_;
    foreach my $key (keys %args) {
        (my $attr = $key) =~ s/^-//;
        $self->{$attr} = $args{$key};
    }
    return $self;
}

# fetch: Class method that parses the HTTP_COOKIE environment variable.
# Returns a hash where keys are cookie names and values are CGI::Cookie objects.
sub fetch {
    my %cookies;
    if ($ENV{HTTP_COOKIE}) {
        foreach my $pair (split /;\s*/, $ENV{HTTP_COOKIE}) {
            my ($name, $value) = split /=/, $pair, 2;
            $value = defined $value ? uri_unescape($value) : '';
            # Create a cookie object for each cookie found.
            $cookies{$name} = CGI::Cookie->new(-name=>$name, -value=>$value);
        }
    }
    return %cookies;
}

1;
