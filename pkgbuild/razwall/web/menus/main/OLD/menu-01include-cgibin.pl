#!/usr/bin/perl
foreach my $regfile (glob("/razwall/web/cgi-bin/menu-*.pl")) {
    require $regfile;
}
1;
