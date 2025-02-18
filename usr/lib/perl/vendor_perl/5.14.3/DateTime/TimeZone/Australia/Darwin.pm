# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/australasia.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Australia::Darwin;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Australia::Darwin::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
59771575000,
DateTime::TimeZone::NEG_INFINITY,
59771606400,
31400,
0,
'LMT'
    ],
    [
59771575000,
59905494000,
59771607400,
59905526400,
32400,
0,
'CST'
    ],
    [
59905494000,
60463117860,
59905528200,
60463152060,
34200,
0,
'CST'
    ],
    [
60463117860,
60470292600,
60463155660,
60470330400,
37800,
1,
'CST'
    ],
    [
60470292600,
61252043400,
60470326800,
61252077600,
34200,
0,
'CST'
    ],
    [
61252043400,
61259556600,
61252081200,
61259594400,
37800,
1,
'CST'
    ],
    [
61259556600,
61275285000,
61259590800,
61275319200,
34200,
0,
'CST'
    ],
    [
61275285000,
61291006200,
61275322800,
61291044000,
37800,
1,
'CST'
    ],
    [
61291006200,
61307339400,
61291040400,
61307373600,
34200,
0,
'CST'
    ],
    [
61307339400,
61322455800,
61307377200,
61322493600,
37800,
1,
'CST'
    ],
    [
61322455800,
DateTime::TimeZone::INFINITY,
61322421600,
DateTime::TimeZone::INFINITY,
34200,
0,
'CST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

