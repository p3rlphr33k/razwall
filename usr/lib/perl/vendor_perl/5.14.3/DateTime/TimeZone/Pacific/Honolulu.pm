# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/northamerica.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Pacific::Honolulu;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Pacific::Honolulu::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
59926775486,
DateTime::TimeZone::NEG_INFINITY,
59926737600,
-37886,
0,
'LMT'
    ],
    [
59926775486,
60978400200,
59926737686,
60978362400,
-37800,
0,
'HST'
    ],
    [
60978400200,
60980211000,
60978366000,
60980176800,
-34200,
1,
'HDT'
    ],
    [
60980211000,
61255485000,
60980173200,
61255447200,
-37800,
0,
'HST'
    ],
    [
61255485000,
61366287600,
61255450800,
61366253400,
-34200,
1,
'HWT'
    ],
    [
61366287600,
61370307000,
61366253400,
61370272800,
-34200,
1,
'HPT'
    ],
    [
61370307000,
61423533000,
61370269200,
61423495200,
-37800,
0,
'HST'
    ],
    [
61423533000,
DateTime::TimeZone::INFINITY,
61423569000,
DateTime::TimeZone::INFINITY,
-36000,
0,
'HST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

