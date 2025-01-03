# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/asia.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Asia::Tokyo;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Asia::Tokyo::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
59547970800,
DateTime::TimeZone::NEG_INFINITY,
59548004339,
33539,
0,
'LMT'
    ],
    [
59547970800,
59800431600,
59548003200,
59800464000,
32400,
0,
'JST'
    ],
    [
59800431600,
61125807600,
59800464000,
61125840000,
32400,
0,
'CJT'
    ],
    [
61125807600,
DateTime::TimeZone::INFINITY,
61125775200,
DateTime::TimeZone::INFINITY,
32400,
0,
'JST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

