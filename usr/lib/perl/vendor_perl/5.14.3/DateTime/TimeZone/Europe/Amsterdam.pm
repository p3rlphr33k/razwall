# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/europe.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Europe::Amsterdam;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Europe::Amsterdam::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
57875470828,
DateTime::TimeZone::NEG_INFINITY,
57875472000,
1172,
0,
'LMT'
    ],
    [
57875470828,
60441982828,
57875472000,
60441984000,
1172,
0,
''
    ],
    [
60441982828,
60455198428,
60441987600,
60455203200,
4772,
1,
'NST'
    ],
    [
60455198428,
60472230028,
60455199600,
60472231200,
1172,
0,
'AMT'
    ],
    [
60472230028,
60485535628,
60472234800,
60485540400,
4772,
1,
'NST'
    ],
    [
60485535628,
60502470028,
60485536800,
60502471200,
1172,
0,
'AMT'
    ],
    [
60502470028,
60518194828,
60502474800,
60518199600,
4772,
1,
'NST'
    ],
    [
60518194828,
60534524428,
60518196000,
60534525600,
1172,
0,
'AMT'
    ],
    [
60534524428,
60549644428,
60534529200,
60549649200,
4772,
1,
'NST'
    ],
    [
60549644428,
60565974028,
60549645600,
60565975200,
1172,
0,
'AMT'
    ],
    [
60565974028,
60581094028,
60565978800,
60581098800,
4772,
1,
'NST'
    ],
    [
60581094028,
60597423628,
60581095200,
60597424800,
1172,
0,
'AMT'
    ],
    [
60597423628,
60612543628,
60597428400,
60612548400,
4772,
1,
'NST'
    ],
    [
60612543628,
60628182028,
60612544800,
60628183200,
1172,
0,
'AMT'
    ],
    [
60628182028,
60645116428,
60628186800,
60645121200,
4772,
1,
'NST'
    ],
    [
60645116428,
60665506828,
60645117600,
60665508000,
1172,
0,
'AMT'
    ],
    [
60665506828,
60676566028,
60665511600,
60676570800,
4772,
1,
'NST'
    ],
    [
60676566028,
60691686028,
60676567200,
60691687200,
1172,
0,
'AMT'
    ],
    [
60691686028,
60708015628,
60691690800,
60708020400,
4772,
1,
'NST'
    ],
    [
60708015628,
60729010828,
60708016800,
60729012000,
1172,
0,
'AMT'
    ],
    [
60729010828,
60739465228,
60729015600,
60739470000,
4772,
1,
'NST'
    ],
    [
60739465228,
60758732428,
60739466400,
60758733600,
1172,
0,
'AMT'
    ],
    [
60758732428,
60770914828,
60758737200,
60770919600,
4772,
1,
'NST'
    ],
    [
60770914828,
60790268428,
60770916000,
60790269600,
1172,
0,
'AMT'
    ],
    [
60790268428,
60802364428,
60790273200,
60802369200,
4772,
1,
'NST'
    ],
    [
60802364428,
60821890828,
60802365600,
60821892000,
1172,
0,
'AMT'
    ],
    [
60821890828,
60834418828,
60821895600,
60834423600,
4772,
1,
'NST'
    ],
    [
60834418828,
60853426828,
60834420000,
60853428000,
1172,
0,
'AMT'
    ],
    [
60853426828,
60865868428,
60853431600,
60865873200,
4772,
1,
'NST'
    ],
    [
60865868428,
60884962828,
60865869600,
60884964000,
1172,
0,
'AMT'
    ],
    [
60884962828,
60897318028,
60884967600,
60897322800,
4772,
1,
'NST'
    ],
    [
60897318028,
60916498828,
60897319200,
60916500000,
1172,
0,
'AMT'
    ],
    [
60916498828,
60928767628,
60916503600,
60928772400,
4772,
1,
'NST'
    ],
    [
60928767628,
60948726028,
60928768800,
60948727200,
1172,
0,
'AMT'
    ],
    [
60948726028,
60960217228,
60948730800,
60960222000,
4772,
1,
'NST'
    ],
    [
60960217228,
60979657228,
60960218400,
60979658400,
1172,
0,
'AMT'
    ],
    [
60979657228,
60992271628,
60979662000,
60992276400,
4772,
1,
'NST'
    ],
    [
60992271628,
61011193228,
60992272800,
61011194400,
1172,
0,
'AMT'
    ],
    [
61011193228,
61023721228,
61011198000,
61023726000,
4772,
1,
'NST'
    ],
    [
61023721228,
61042729228,
61023722400,
61042730400,
1172,
0,
'AMT'
    ],
    [
61042729228,
61055170828,
61042734000,
61055175600,
4772,
1,
'NST'
    ],
    [
61055170828,
61074351628,
61055172000,
61074352800,
1172,
0,
'AMT'
    ],
    [
61074351628,
61086620428,
61074356400,
61086625200,
4772,
1,
'NST'
    ],
    [
61086620428,
61106492428,
61086621600,
61106493600,
1172,
0,
'AMT'
    ],
    [
61106492428,
61109937628,
61106497200,
61109942400,
4772,
1,
'NST'
    ],
    [
61109937628,
61118070000,
61109942428,
61118074800,
4800,
1,
'NEST'
    ],
    [
61118070000,
61137423600,
61118071200,
61137424800,
1200,
0,
'NET'
    ],
    [
61137423600,
61149519600,
61137428400,
61149524400,
4800,
1,
'NEST'
    ],
    [
61149519600,
61168959600,
61149520800,
61168960800,
1200,
0,
'NET'
    ],
    [
61168959600,
61181574000,
61168964400,
61181578800,
4800,
1,
'NEST'
    ],
    [
61181574000,
61200661200,
61181575200,
61200662400,
1200,
0,
'NET'
    ],
    [
61200661200,
61278426000,
61200668400,
61278433200,
7200,
1,
'CEST'
    ],
    [
61278426000,
61291126800,
61278429600,
61291130400,
3600,
0,
'CET'
    ],
    [
61291126800,
61307456400,
61291134000,
61307463600,
7200,
1,
'CEST'
    ],
    [
61307456400,
61323181200,
61307460000,
61323184800,
3600,
0,
'CET'
    ],
    [
61323181200,
61338906000,
61323188400,
61338913200,
7200,
1,
'CEST'
    ],
    [
61338906000,
61354630800,
61338909600,
61354634400,
3600,
0,
'CET'
    ],
    [
61354630800,
61369059600,
61354638000,
61369066800,
7200,
1,
'CEST'
    ],
    [
61369059600,
62356604400,
61369063200,
62356608000,
3600,
0,
'CET'
    ],
    [
62356604400,
62364560400,
62356608000,
62364564000,
3600,
0,
'CET'
    ],
    [
62364560400,
62379680400,
62364567600,
62379687600,
7200,
1,
'CEST'
    ],
    [
62379680400,
62396010000,
62379684000,
62396013600,
3600,
0,
'CET'
    ],
    [
62396010000,
62411734800,
62396017200,
62411742000,
7200,
1,
'CEST'
    ],
    [
62411734800,
62427459600,
62411738400,
62427463200,
3600,
0,
'CET'
    ],
    [
62427459600,
62443184400,
62427466800,
62443191600,
7200,
1,
'CEST'
    ],
    [
62443184400,
62459514000,
62443188000,
62459517600,
3600,
0,
'CET'
    ],
    [
62459514000,
62474634000,
62459521200,
62474641200,
7200,
1,
'CEST'
    ],
    [
62474634000,
62490358800,
62474637600,
62490362400,
3600,
0,
'CET'
    ],
    [
62490358800,
62506083600,
62490366000,
62506090800,
7200,
1,
'CEST'
    ],
    [
62506083600,
62521808400,
62506087200,
62521812000,
3600,
0,
'CET'
    ],
    [
62521808400,
62537533200,
62521815600,
62537540400,
7200,
1,
'CEST'
    ],
    [
62537533200,
62553258000,
62537536800,
62553261600,
3600,
0,
'CET'
    ],
    [
62553258000,
62568982800,
62553265200,
62568990000,
7200,
1,
'CEST'
    ],
    [
62568982800,
62584707600,
62568986400,
62584711200,
3600,
0,
'CET'
    ],
    [
62584707600,
62601037200,
62584714800,
62601044400,
7200,
1,
'CEST'
    ],
    [
62601037200,
62616762000,
62601040800,
62616765600,
3600,
0,
'CET'
    ],
    [
62616762000,
62632486800,
62616769200,
62632494000,
7200,
1,
'CEST'
    ],
    [
62632486800,
62648211600,
62632490400,
62648215200,
3600,
0,
'CET'
    ],
    [
62648211600,
62663936400,
62648218800,
62663943600,
7200,
1,
'CEST'
    ],
    [
62663936400,
62679661200,
62663940000,
62679664800,
3600,
0,
'CET'
    ],
    [
62679661200,
62695386000,
62679668400,
62695393200,
7200,
1,
'CEST'
    ],
    [
62695386000,
62711110800,
62695389600,
62711114400,
3600,
0,
'CET'
    ],
    [
62711110800,
62726835600,
62711118000,
62726842800,
7200,
1,
'CEST'
    ],
    [
62726835600,
62742560400,
62726839200,
62742564000,
3600,
0,
'CET'
    ],
    [
62742560400,
62758285200,
62742567600,
62758292400,
7200,
1,
'CEST'
    ],
    [
62758285200,
62774010000,
62758288800,
62774013600,
3600,
0,
'CET'
    ],
    [
62774010000,
62790339600,
62774017200,
62790346800,
7200,
1,
'CEST'
    ],
    [
62790339600,
62806064400,
62790343200,
62806068000,
3600,
0,
'CET'
    ],
    [
62806064400,
62821789200,
62806071600,
62821796400,
7200,
1,
'CEST'
    ],
    [
62821789200,
62837514000,
62821792800,
62837517600,
3600,
0,
'CET'
    ],
    [
62837514000,
62853238800,
62837521200,
62853246000,
7200,
1,
'CEST'
    ],
    [
62853238800,
62868963600,
62853242400,
62868967200,
3600,
0,
'CET'
    ],
    [
62868963600,
62884688400,
62868970800,
62884695600,
7200,
1,
'CEST'
    ],
    [
62884688400,
62900413200,
62884692000,
62900416800,
3600,
0,
'CET'
    ],
    [
62900413200,
62916138000,
62900420400,
62916145200,
7200,
1,
'CEST'
    ],
    [
62916138000,
62931862800,
62916141600,
62931866400,
3600,
0,
'CET'
    ],
    [
62931862800,
62947587600,
62931870000,
62947594800,
7200,
1,
'CEST'
    ],
    [
62947587600,
62963917200,
62947591200,
62963920800,
3600,
0,
'CET'
    ],
    [
62963917200,
62982061200,
62963924400,
62982068400,
7200,
1,
'CEST'
    ],
    [
62982061200,
62995366800,
62982064800,
62995370400,
3600,
0,
'CET'
    ],
    [
62995366800,
63013510800,
62995374000,
63013518000,
7200,
1,
'CEST'
    ],
    [
63013510800,
63026816400,
63013514400,
63026820000,
3600,
0,
'CET'
    ],
    [
63026816400,
63044960400,
63026823600,
63044967600,
7200,
1,
'CEST'
    ],
    [
63044960400,
63058266000,
63044964000,
63058269600,
3600,
0,
'CET'
    ],
    [
63058266000,
63077014800,
63058273200,
63077022000,
7200,
1,
'CEST'
    ],
    [
63077014800,
63089715600,
63077018400,
63089719200,
3600,
0,
'CET'
    ],
    [
63089715600,
63108464400,
63089722800,
63108471600,
7200,
1,
'CEST'
    ],
    [
63108464400,
63121165200,
63108468000,
63121168800,
3600,
0,
'CET'
    ],
    [
63121165200,
63139914000,
63121172400,
63139921200,
7200,
1,
'CEST'
    ],
    [
63139914000,
63153219600,
63139917600,
63153223200,
3600,
0,
'CET'
    ],
    [
63153219600,
63171363600,
63153226800,
63171370800,
7200,
1,
'CEST'
    ],
    [
63171363600,
63184669200,
63171367200,
63184672800,
3600,
0,
'CET'
    ],
    [
63184669200,
63202813200,
63184676400,
63202820400,
7200,
1,
'CEST'
    ],
    [
63202813200,
63216118800,
63202816800,
63216122400,
3600,
0,
'CET'
    ],
    [
63216118800,
63234867600,
63216126000,
63234874800,
7200,
1,
'CEST'
    ],
    [
63234867600,
63247568400,
63234871200,
63247572000,
3600,
0,
'CET'
    ],
    [
63247568400,
63266317200,
63247575600,
63266324400,
7200,
1,
'CEST'
    ],
    [
63266317200,
63279018000,
63266320800,
63279021600,
3600,
0,
'CET'
    ],
    [
63279018000,
63297766800,
63279025200,
63297774000,
7200,
1,
'CEST'
    ],
    [
63297766800,
63310467600,
63297770400,
63310471200,
3600,
0,
'CET'
    ],
    [
63310467600,
63329216400,
63310474800,
63329223600,
7200,
1,
'CEST'
    ],
    [
63329216400,
63342522000,
63329220000,
63342525600,
3600,
0,
'CET'
    ],
    [
63342522000,
63360666000,
63342529200,
63360673200,
7200,
1,
'CEST'
    ],
    [
63360666000,
63373971600,
63360669600,
63373975200,
3600,
0,
'CET'
    ],
    [
63373971600,
63392115600,
63373978800,
63392122800,
7200,
1,
'CEST'
    ],
    [
63392115600,
63405421200,
63392119200,
63405424800,
3600,
0,
'CET'
    ],
    [
63405421200,
63424170000,
63405428400,
63424177200,
7200,
1,
'CEST'
    ],
    [
63424170000,
63436870800,
63424173600,
63436874400,
3600,
0,
'CET'
    ],
    [
63436870800,
63455619600,
63436878000,
63455626800,
7200,
1,
'CEST'
    ],
    [
63455619600,
63468320400,
63455623200,
63468324000,
3600,
0,
'CET'
    ],
    [
63468320400,
63487069200,
63468327600,
63487076400,
7200,
1,
'CEST'
    ],
    [
63487069200,
63500374800,
63487072800,
63500378400,
3600,
0,
'CET'
    ],
    [
63500374800,
63518518800,
63500382000,
63518526000,
7200,
1,
'CEST'
    ],
    [
63518518800,
63531824400,
63518522400,
63531828000,
3600,
0,
'CET'
    ],
    [
63531824400,
63549968400,
63531831600,
63549975600,
7200,
1,
'CEST'
    ],
    [
63549968400,
63563274000,
63549972000,
63563277600,
3600,
0,
'CET'
    ],
    [
63563274000,
63581418000,
63563281200,
63581425200,
7200,
1,
'CEST'
    ],
    [
63581418000,
63594723600,
63581421600,
63594727200,
3600,
0,
'CET'
    ],
    [
63594723600,
63613472400,
63594730800,
63613479600,
7200,
1,
'CEST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}

sub _last_offset { 3600 }

my $last_observance = bless( {
  'format' => 'CE%sT',
  'gmtoff' => '1:00',
  'local_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 721720,
    'local_rd_secs' => 0,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 721720,
    'utc_rd_secs' => 0,
    'utc_year' => 1978
  }, 'DateTime' ),
  'offset_from_std' => 0,
  'offset_from_utc' => 3600,
  'until' => [],
  'utc_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 721719,
    'local_rd_secs' => 82800,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 721719,
    'utc_rd_secs' => 82800,
    'utc_year' => 1977
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
