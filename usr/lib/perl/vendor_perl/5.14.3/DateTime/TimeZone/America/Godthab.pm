# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/europe.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::America::Godthab;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::America::Godthab::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
60449599616,
DateTime::TimeZone::NEG_INFINITY,
60449587200,
-12416,
0,
'LMT'
    ],
    [
60449599616,
62459528400,
60449588816,
62459517600,
-10800,
0,
'WGT'
    ],
    [
62459528400,
62474634000,
62459521200,
62474626800,
-7200,
1,
'WGST'
    ],
    [
62474634000,
62490358800,
62474623200,
62490348000,
-10800,
0,
'WGT'
    ],
    [
62490358800,
62506083600,
62490351600,
62506076400,
-7200,
1,
'WGST'
    ],
    [
62506083600,
62521808400,
62506072800,
62521797600,
-10800,
0,
'WGT'
    ],
    [
62521808400,
62537533200,
62521801200,
62537526000,
-7200,
1,
'WGST'
    ],
    [
62537533200,
62553258000,
62537522400,
62553247200,
-10800,
0,
'WGT'
    ],
    [
62553258000,
62568982800,
62553250800,
62568975600,
-7200,
1,
'WGST'
    ],
    [
62568982800,
62584707600,
62568972000,
62584696800,
-10800,
0,
'WGT'
    ],
    [
62584707600,
62601037200,
62584700400,
62601030000,
-7200,
1,
'WGST'
    ],
    [
62601037200,
62616762000,
62601026400,
62616751200,
-10800,
0,
'WGT'
    ],
    [
62616762000,
62632486800,
62616754800,
62632479600,
-7200,
1,
'WGST'
    ],
    [
62632486800,
62648211600,
62632476000,
62648200800,
-10800,
0,
'WGT'
    ],
    [
62648211600,
62663936400,
62648204400,
62663929200,
-7200,
1,
'WGST'
    ],
    [
62663936400,
62679661200,
62663925600,
62679650400,
-10800,
0,
'WGT'
    ],
    [
62679661200,
62695386000,
62679654000,
62695378800,
-7200,
1,
'WGST'
    ],
    [
62695386000,
62711110800,
62695375200,
62711100000,
-10800,
0,
'WGT'
    ],
    [
62711110800,
62726835600,
62711103600,
62726828400,
-7200,
1,
'WGST'
    ],
    [
62726835600,
62742560400,
62726824800,
62742549600,
-10800,
0,
'WGT'
    ],
    [
62742560400,
62758285200,
62742553200,
62758278000,
-7200,
1,
'WGST'
    ],
    [
62758285200,
62774010000,
62758274400,
62773999200,
-10800,
0,
'WGT'
    ],
    [
62774010000,
62790339600,
62774002800,
62790332400,
-7200,
1,
'WGST'
    ],
    [
62790339600,
62806064400,
62790328800,
62806053600,
-10800,
0,
'WGT'
    ],
    [
62806064400,
62821789200,
62806057200,
62821782000,
-7200,
1,
'WGST'
    ],
    [
62821789200,
62837514000,
62821778400,
62837503200,
-10800,
0,
'WGT'
    ],
    [
62837514000,
62853238800,
62837506800,
62853231600,
-7200,
1,
'WGST'
    ],
    [
62853238800,
62868963600,
62853228000,
62868952800,
-10800,
0,
'WGT'
    ],
    [
62868963600,
62884688400,
62868956400,
62884681200,
-7200,
1,
'WGST'
    ],
    [
62884688400,
62900413200,
62884677600,
62900402400,
-10800,
0,
'WGT'
    ],
    [
62900413200,
62916138000,
62900406000,
62916130800,
-7200,
1,
'WGST'
    ],
    [
62916138000,
62931862800,
62916127200,
62931852000,
-10800,
0,
'WGT'
    ],
    [
62931862800,
62947587600,
62931855600,
62947580400,
-7200,
1,
'WGST'
    ],
    [
62947587600,
62963917200,
62947576800,
62963906400,
-10800,
0,
'WGT'
    ],
    [
62963917200,
62982061200,
62963910000,
62982054000,
-7200,
1,
'WGST'
    ],
    [
62982061200,
62995366800,
62982050400,
62995356000,
-10800,
0,
'WGT'
    ],
    [
62995366800,
63013510800,
62995359600,
63013503600,
-7200,
1,
'WGST'
    ],
    [
63013510800,
63026816400,
63013500000,
63026805600,
-10800,
0,
'WGT'
    ],
    [
63026816400,
63044960400,
63026809200,
63044953200,
-7200,
1,
'WGST'
    ],
    [
63044960400,
63058266000,
63044949600,
63058255200,
-10800,
0,
'WGT'
    ],
    [
63058266000,
63077014800,
63058258800,
63077007600,
-7200,
1,
'WGST'
    ],
    [
63077014800,
63089715600,
63077004000,
63089704800,
-10800,
0,
'WGT'
    ],
    [
63089715600,
63108464400,
63089708400,
63108457200,
-7200,
1,
'WGST'
    ],
    [
63108464400,
63121165200,
63108453600,
63121154400,
-10800,
0,
'WGT'
    ],
    [
63121165200,
63139914000,
63121158000,
63139906800,
-7200,
1,
'WGST'
    ],
    [
63139914000,
63153219600,
63139903200,
63153208800,
-10800,
0,
'WGT'
    ],
    [
63153219600,
63171363600,
63153212400,
63171356400,
-7200,
1,
'WGST'
    ],
    [
63171363600,
63184669200,
63171352800,
63184658400,
-10800,
0,
'WGT'
    ],
    [
63184669200,
63202813200,
63184662000,
63202806000,
-7200,
1,
'WGST'
    ],
    [
63202813200,
63216118800,
63202802400,
63216108000,
-10800,
0,
'WGT'
    ],
    [
63216118800,
63234867600,
63216111600,
63234860400,
-7200,
1,
'WGST'
    ],
    [
63234867600,
63247568400,
63234856800,
63247557600,
-10800,
0,
'WGT'
    ],
    [
63247568400,
63266317200,
63247561200,
63266310000,
-7200,
1,
'WGST'
    ],
    [
63266317200,
63279018000,
63266306400,
63279007200,
-10800,
0,
'WGT'
    ],
    [
63279018000,
63297766800,
63279010800,
63297759600,
-7200,
1,
'WGST'
    ],
    [
63297766800,
63310467600,
63297756000,
63310456800,
-10800,
0,
'WGT'
    ],
    [
63310467600,
63329216400,
63310460400,
63329209200,
-7200,
1,
'WGST'
    ],
    [
63329216400,
63342522000,
63329205600,
63342511200,
-10800,
0,
'WGT'
    ],
    [
63342522000,
63360666000,
63342514800,
63360658800,
-7200,
1,
'WGST'
    ],
    [
63360666000,
63373971600,
63360655200,
63373960800,
-10800,
0,
'WGT'
    ],
    [
63373971600,
63392115600,
63373964400,
63392108400,
-7200,
1,
'WGST'
    ],
    [
63392115600,
63405421200,
63392104800,
63405410400,
-10800,
0,
'WGT'
    ],
    [
63405421200,
63424170000,
63405414000,
63424162800,
-7200,
1,
'WGST'
    ],
    [
63424170000,
63436870800,
63424159200,
63436860000,
-10800,
0,
'WGT'
    ],
    [
63436870800,
63455619600,
63436863600,
63455612400,
-7200,
1,
'WGST'
    ],
    [
63455619600,
63468320400,
63455608800,
63468309600,
-10800,
0,
'WGT'
    ],
    [
63468320400,
63487069200,
63468313200,
63487062000,
-7200,
1,
'WGST'
    ],
    [
63487069200,
63500374800,
63487058400,
63500364000,
-10800,
0,
'WGT'
    ],
    [
63500374800,
63518518800,
63500367600,
63518511600,
-7200,
1,
'WGST'
    ],
    [
63518518800,
63531824400,
63518508000,
63531813600,
-10800,
0,
'WGT'
    ],
    [
63531824400,
63549968400,
63531817200,
63549961200,
-7200,
1,
'WGST'
    ],
    [
63549968400,
63563274000,
63549957600,
63563263200,
-10800,
0,
'WGT'
    ],
    [
63563274000,
63581418000,
63563266800,
63581410800,
-7200,
1,
'WGST'
    ],
    [
63581418000,
63594723600,
63581407200,
63594712800,
-10800,
0,
'WGT'
    ],
    [
63594723600,
63613472400,
63594716400,
63613465200,
-7200,
1,
'WGST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}

sub _last_offset { -10800 }

my $last_observance = bless( {
  'format' => 'WG%sT',
  'gmtoff' => '-3:00',
  'local_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 722911,
    'local_rd_secs' => 10800,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 722911,
    'utc_rd_secs' => 10800,
    'utc_year' => 1981
  }, 'DateTime' ),
  'offset_from_std' => 0,
  'offset_from_utc' => -10800,
  'until' => [],
  'utc_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 722911,
    'local_rd_secs' => 18000,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 722911,
    'utc_rd_secs' => 18000,
    'utc_year' => 1981
  }, 'DateTime' )
}, 'DateTime::TimeZone::OlsonDB::Observance' )
;
sub _last_observance { $last_observance }

my $rules = [
  bless( {
    'at' => '1:00u',
    'from' => '1996',
    'in' => 'Oct',
    'letter' => '',
    'name' => 'EU',
    'offset_from_std' => 0,
    'on' => 'lastSun',
    'save' => '0',
    'to' => 'max',
    'type' => undef
  }, 'DateTime::TimeZone::OlsonDB::Rule' ),
  bless( {
    'at' => '1:00u',
    'from' => '1981',
    'in' => 'Mar',
    'letter' => 'S',
    'name' => 'EU',
    'offset_from_std' => 3600,
    'on' => 'lastSun',
    'save' => '1:00',
    'to' => 'max',
    'type' => undef
  }, 'DateTime::TimeZone::OlsonDB::Rule' )
]
;
sub _rules { $rules }


1;

