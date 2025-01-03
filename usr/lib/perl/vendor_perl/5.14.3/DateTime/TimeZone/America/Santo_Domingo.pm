# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/northamerica.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::America::Santo_Domingo;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::America::Santo_Domingo::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
59611178376,
DateTime::TimeZone::NEG_INFINITY,
59611161600,
-16776,
0,
'LMT'
    ],
    [
59611178376,
60975909600,
59611161576,
60975892800,
-16800,
0,
'SDMT'
    ],
    [
60975909600,
62035563600,
60975891600,
62035545600,
-18000,
0,
'ET'
    ],
    [
62035563600,
62046014400,
62035549200,
62046000000,
-14400,
1,
'EDT'
    ],
    [
62046014400,
62129912400,
62045996400,
62129894400,
-18000,
0,
'EST'
    ],
    [
62129912400,
62140105800,
62129896200,
62140089600,
-16200,
1,
'EHDT'
    ],
    [
62140105800,
62161362000,
62140087800,
62161344000,
-18000,
0,
'EST'
    ],
    [
62161362000,
62168877000,
62161345800,
62168860800,
-16200,
1,
'EHDT'
    ],
    [
62168877000,
62193416400,
62168859000,
62193398400,
-18000,
0,
'EST'
    ],
    [
62193416400,
62200499400,
62193400200,
62200483200,
-16200,
1,
'EHDT'
    ],
    [
62200499400,
62224866000,
62200481400,
62224848000,
-18000,
0,
'EST'
    ],
    [
62224866000,
62232121800,
62224849800,
62232105600,
-16200,
1,
'EHDT'
    ],
    [
62232121800,
62256315600,
62232103800,
62256297600,
-18000,
0,
'EST'
    ],
    [
62256315600,
62263657800,
62256299400,
62263641600,
-16200,
1,
'EHDT'
    ],
    [
62263657800,
62287765200,
62263639800,
62287747200,
-18000,
0,
'EST'
    ],
    [
62287765200,
63108482400,
62287750800,
63108468000,
-14400,
0,
'AST'
    ],
    [
63108482400,
63111506400,
63108464400,
63111488400,
-18000,
0,
'EST'
    ],
    [
63111506400,
DateTime::TimeZone::INFINITY,
63111520800,
DateTime::TimeZone::INFINITY,
-14400,
0,
'AST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

