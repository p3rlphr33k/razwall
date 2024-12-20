# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/northamerica.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::America::Hermosillo;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::America::Hermosillo::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
60620943600,
DateTime::TimeZone::NEG_INFINITY,
60620916968,
-26632,
0,
'LMT'
    ],
    [
60620943600,
60792616800,
60620918400,
60792591600,
-25200,
0,
'MST'
    ],
    [
60792616800,
60900876000,
60792595200,
60900854400,
-21600,
0,
'CST'
    ],
    [
60900876000,
60915391200,
60900850800,
60915366000,
-25200,
0,
'MST'
    ],
    [
60915391200,
60928524000,
60915369600,
60928502400,
-21600,
0,
'CST'
    ],
    [
60928524000,
60944338800,
60928498800,
60944313600,
-25200,
0,
'MST'
    ],
    [
60944338800,
61261855200,
60944317200,
61261833600,
-21600,
0,
'CST'
    ],
    [
61261855200,
61474143600,
61261830000,
61474118400,
-25200,
0,
'MST'
    ],
    [
61474143600,
62135712000,
61474114800,
62135683200,
-28800,
0,
'PST'
    ],
    [
62135712000,
62964550800,
62135686800,
62964525600,
-25200,
0,
'MST'
    ],
    [
62964550800,
62982086400,
62964529200,
62982064800,
-21600,
1,
'MDT'
    ],
    [
62982086400,
62996000400,
62982061200,
62995975200,
-25200,
0,
'MST'
    ],
    [
62996000400,
63013536000,
62995978800,
63013514400,
-21600,
1,
'MDT'
    ],
    [
63013536000,
63027450000,
63013510800,
63027424800,
-25200,
0,
'MST'
    ],
    [
63027450000,
63044985600,
63027428400,
63044964000,
-21600,
1,
'MDT'
    ],
    [
63044985600,
63050857200,
63044960400,
63050832000,
-25200,
0,
'MST'
    ],
    [
63050857200,
DateTime::TimeZone::INFINITY,
63050882400,
DateTime::TimeZone::INFINITY,
-25200,
0,
'MST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

