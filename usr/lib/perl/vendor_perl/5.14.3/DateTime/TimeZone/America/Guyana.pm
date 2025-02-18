# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/southamerica.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::America::Guyana;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::America::Guyana::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
60405105160,
DateTime::TimeZone::NEG_INFINITY,
60405091200,
-13960,
0,
'LMT'
    ],
    [
60405105160,
62021994300,
60405091660,
62021980800,
-13500,
0,
'GBGT'
    ],
    [
62021994300,
62311693500,
62021980800,
62311680000,
-13500,
0,
'GYT'
    ],
    [
62311693500,
62798382000,
62311682700,
62798371200,
-10800,
0,
'GYT'
    ],
    [
62798382000,
DateTime::TimeZone::INFINITY,
62798396400,
DateTime::TimeZone::INFINITY,
-14400,
0,
'GYT'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

