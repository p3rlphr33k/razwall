#!/usr/bin/perl

require "header.pl";

calcURI();
checkForLogout();
checkForHASlave();
genFlavourMenus();
    
print "Pragma: no-cache\n";
print "Cache-control: no-cache\n";
print "Connection: close\n";
print "Content-type: text/html\n\n";

print menu_to_json();
