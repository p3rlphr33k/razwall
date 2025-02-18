# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/africa.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Indian::Reunion;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Indian::Reunion::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
60286796288,
DateTime::TimeZone::NEG_INFINITY,
60286809600,
13312,
0,
'LMT'
    ],
    [
60286796288,
DateTime::TimeZone::INFINITY,
60286781888,
DateTime::TimeZone::INFINITY,
14400,
0,
'RET'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

