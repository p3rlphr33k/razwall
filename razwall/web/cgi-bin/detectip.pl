#!/usr/bin/perl

sub readip {
    $url = 'http://checkip.dyndns.org';
    $response = `wget -q -O - $url`;
    die "Failed to fetch content from $url" if $? != 0;

    if ($response =~ /([\d]+\.[\d]+\.[\d]+\.[\d]+)/) {
        return $1;
    } else {
        die "Failed to extract IP address from response";
    }
}

print readip();

