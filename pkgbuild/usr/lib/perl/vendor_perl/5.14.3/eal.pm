package eal;
use strict;
use LWP::UserAgent;
use JSON::XS;


sub new {
    my $proto = shift;
    my $scope = shift;
    my $debug = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    $self->{url} = 'http://localhost:3132/';
    $self->{debug} = $debug;
    $self->{scope} = $scope;
    $self->debug("Instantiated with scope ".$self->{scope});
    return $self;
}

sub debug {
    my $self = shift;
    if (! $self->{debug}) {
	return;
    }
    warn(@_);
}

sub listUsers {
    my $self = shift;
    my $filterref = shift;
    my $attribref = shift;
    my @filter = @$filterref;
    my @attrib = @$attribref;

    my $url = $self->{url} . 'list_users/?scope=' . $self->{scope};
    foreach my $key (@filter) {
	$url .= "&$key";
    }
    foreach my $key (@attrib) {
	$url .= "&retrieve_attributes=$key";
    }
    $self->_get($url);
}

sub _get {
    my $self = shift;
    my $url = shift;
    $self->debug("Retrieve from url: $url");

    my $agent = LWP::UserAgent->new();
    my $reqest = HTTP::Request->new(GET => $url);
    $reqest->header('Accept' => 'text/html');
    # send request
    my $response = $agent->request($reqest);

    # check the outcome
    if (! $response->is_success) {
	$self->debug("Failed to get values");
	return 0;
    }
    my $content = $response->content();
    $self->debug("Got values: \n$content");
    return JSON::XS->new->latin1->decode($content);
}

1;

