#!/usr/bin/perl
foreach my $regfile (glob("/home/httpd/cgi-bin/menu-*.pl")) {
    require $regfile;
}
1;
