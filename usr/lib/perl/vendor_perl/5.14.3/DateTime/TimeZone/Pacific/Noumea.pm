# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/australasia.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Pacific::Noumea;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Pacific::Noumea::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
60306296052,
DateTime::TimeZone::NEG_INFINITY,
60306336000,
39948,
0,
'LMT'
    ],
    [
60306296052,
62385685200,
60306335652,
62385724800,
39600,
0,
'NCT'
    ],
    [
62385685200,
62393025600,
62385728400,
62393068800,
43200,
1,
'NCST'
    ],
    [
62393025600,
62417134800,
62393065200,
62417174400,
39600,
0,
'NCT'
    ],
    [
62417134800,
62424561600,
62417178000,
62424604800,
43200,
1,
'NCST'
    ],
    [
62424561600,
62985049200,
62424601200,
62985088800,
39600,
0,
'NCT'
    ],
    [
62985049200,
62992911600,
62985092400,
62992954800,
43200,
1,
'NCST'
    ],
    [
62992911600,
DateTime::TimeZone::INFINITY,
62992872000,
DateTime::TimeZone::INFINITY,
39600,
0,
'NCT'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

