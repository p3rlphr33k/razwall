# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from ../../data/tz/Olson/europe.  Olson data version 2005l
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Europe::Lisbon;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Europe::Lisbon::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
59421774992,
DateTime::TimeZone::NEG_INFINITY,
59421772800,
-2192,
0,
'LMT'
    ],
    [
59421774992,
60305301392,
59421772800,
60305299200,
-2192,
0,
'LMT'
    ],
    [
60305301392,
60446127600,
60305301392,
60446127600,
0,
0,
'WET'
    ],
    [
60446127600,
60457881600,
60446131200,
60457885200,
3600,
1,
'WEST'
    ],
    [
60457881600,
60468246000,
60457881600,
60468246000,
0,
0,
'WET'
    ],
    [
60468246000,
60487945200,
60468249600,
60487948800,
3600,
1,
'WEST'
    ],
    [
60487945200,
60499868400,
60487945200,
60499868400,
0,
0,
'WET'
    ],
    [
60499868400,
60519481200,
60499872000,
60519484800,
3600,
1,
'WEST'
    ],
    [
60519481200,
60531318000,
60519481200,
60531318000,
0,
0,
'WET'
    ],
    [
60531318000,
60551017200,
60531321600,
60551020800,
3600,
1,
'WEST'
    ],
    [
60551017200,
60562940400,
60551017200,
60562940400,
0,
0,
'WET'
    ],
    [
60562940400,
60582639600,
60562944000,
60582643200,
3600,
1,
'WEST'
    ],
    [
60582639600,
60594476400,
60582639600,
60594476400,
0,
0,
'WET'
    ],
    [
60594476400,
60614175600,
60594480000,
60614179200,
3600,
1,
'WEST'
    ],
    [
60614175600,
60693231600,
60614175600,
60693231600,
0,
0,
'WET'
    ],
    [
60693231600,
60708870000,
60693235200,
60708873600,
3600,
1,
'WEST'
    ],
    [
60708870000,
60756390000,
60708870000,
60756390000,
0,
0,
'WET'
    ],
    [
60756390000,
60770905200,
60756393600,
60770908800,
3600,
1,
'WEST'
    ],
    [
60770905200,
60787234800,
60770905200,
60787234800,
0,
0,
'WET'
    ],
    [
60787234800,
60802354800,
60787238400,
60802358400,
3600,
1,
'WEST'
    ],
    [
60802354800,
60819289200,
60802354800,
60819289200,
0,
0,
'WET'
    ],
    [
60819289200,
60834409200,
60819292800,
60834412800,
3600,
1,
'WEST'
    ],
    [
60834409200,
60851343600,
60834409200,
60851343600,
0,
0,
'WET'
    ],
    [
60851343600,
60865858800,
60851347200,
60865862400,
3600,
1,
'WEST'
    ],
    [
60865858800,
60914242800,
60865858800,
60914242800,
0,
0,
'WET'
    ],
    [
60914242800,
60928758000,
60914246400,
60928761600,
3600,
1,
'WEST'
    ],
    [
60928758000,
60944482800,
60928758000,
60944482800,
0,
0,
'WET'
    ],
    [
60944482800,
60960207600,
60944486400,
60960211200,
3600,
1,
'WEST'
    ],
    [
60960207600,
61007986800,
60960207600,
61007986800,
0,
0,
'WET'
    ],
    [
61007986800,
61023711600,
61007990400,
61023715200,
3600,
1,
'WEST'
    ],
    [
61023711600,
61038831600,
61023711600,
61038831600,
0,
0,
'WET'
    ],
    [
61038831600,
61055161200,
61038835200,
61055164800,
3600,
1,
'WEST'
    ],
    [
61055161200,
61072095600,
61055161200,
61072095600,
0,
0,
'WET'
    ],
    [
61072095600,
61086610800,
61072099200,
61086614400,
3600,
1,
'WEST'
    ],
    [
61086610800,
61102335600,
61086610800,
61102335600,
0,
0,
'WET'
    ],
    [
61102335600,
61118060400,
61102339200,
61118064000,
3600,
1,
'WEST'
    ],
    [
61118060400,
61133180400,
61118060400,
61133180400,
0,
0,
'WET'
    ],
    [
61133180400,
61149510000,
61133184000,
61149513600,
3600,
1,
'WEST'
    ],
    [
61149510000,
61166444400,
61149510000,
61166444400,
0,
0,
'WET'
    ],
    [
61166444400,
61185193200,
61166448000,
61185196800,
3600,
1,
'WEST'
    ],
    [
61185193200,
61193660400,
61185193200,
61193660400,
0,
0,
'WET'
    ],
    [
61193660400,
61213014000,
61193664000,
61213017600,
3600,
1,
'WEST'
    ],
    [
61213014000,
61228738800,
61213014000,
61228738800,
0,
0,
'WET'
    ],
    [
61228738800,
61244550000,
61228742400,
61244553600,
3600,
1,
'WEST'
    ],
    [
61244550000,
61258374000,
61244550000,
61258374000,
0,
0,
'WET'
    ],
    [
61258374000,
61261999200,
61258377600,
61262002800,
3600,
1,
'WEST'
    ],
    [
61261999200,
61271676000,
61262006400,
61271683200,
7200,
1,
'WEMT'
    ],
    [
61271676000,
61277727600,
61271679600,
61277731200,
3600,
1,
'WEST'
    ],
    [
61277727600,
61289823600,
61277727600,
61289823600,
0,
0,
'WET'
    ],
    [
61289823600,
61292844000,
61289827200,
61292847600,
3600,
1,
'WEST'
    ],
    [
61292844000,
61304335200,
61292851200,
61304342400,
7200,
1,
'WEMT'
    ],
    [
61304335200,
61309782000,
61304338800,
61309785600,
3600,
1,
'WEST'
    ],
    [
61309782000,
61321273200,
61309782000,
61321273200,
0,
0,
'WET'
    ],
    [
61321273200,
61324898400,
61321276800,
61324902000,
3600,
1,
'WEST'
    ],
    [
61324898400,
61335784800,
61324905600,
61335792000,
7200,
1,
'WEMT'
    ],
    [
61335784800,
61341231600,
61335788400,
61341235200,
3600,
1,
'WEST'
    ],
    [
61341231600,
61352722800,
61341231600,
61352722800,
0,
0,
'WET'
    ],
    [
61352722800,
61356348000,
61352726400,
61356351600,
3600,
1,
'WEST'
    ],
    [
61356348000,
61367234400,
61356355200,
61367241600,
7200,
1,
'WEMT'
    ],
    [
61367234400,
61372681200,
61367238000,
61372684800,
3600,
1,
'WEST'
    ],
    [
61372681200,
61386591600,
61372681200,
61386591600,
0,
0,
'WET'
    ],
    [
61386591600,
61402316400,
61386595200,
61402320000,
3600,
1,
'WEST'
    ],
    [
61402316400,
61418052000,
61402316400,
61418052000,
0,
0,
'WET'
    ],
    [
61418052000,
61433776800,
61418055600,
61433780400,
3600,
1,
'WEST'
    ],
    [
61433776800,
61449501600,
61433776800,
61449501600,
0,
0,
'WET'
    ],
    [
61449501600,
61465226400,
61449505200,
61465230000,
3600,
1,
'WEST'
    ],
    [
61465226400,
61480951200,
61465226400,
61480951200,
0,
0,
'WET'
    ],
    [
61480951200,
61496676000,
61480954800,
61496679600,
3600,
1,
'WEST'
    ],
    [
61496676000,
61543850400,
61496676000,
61543850400,
0,
0,
'WET'
    ],
    [
61543850400,
61560180000,
61543854000,
61560183600,
3600,
1,
'WEST'
    ],
    [
61560180000,
61575904800,
61560180000,
61575904800,
0,
0,
'WET'
    ],
    [
61575904800,
61591629600,
61575908400,
61591633200,
3600,
1,
'WEST'
    ],
    [
61591629600,
61607354400,
61591629600,
61607354400,
0,
0,
'WET'
    ],
    [
61607354400,
61623079200,
61607358000,
61623082800,
3600,
1,
'WEST'
    ],
    [
61623079200,
61638804000,
61623079200,
61638804000,
0,
0,
'WET'
    ],
    [
61638804000,
61654528800,
61638807600,
61654532400,
3600,
1,
'WEST'
    ],
    [
61654528800,
61670253600,
61654528800,
61670253600,
0,
0,
'WET'
    ],
    [
61670253600,
61685978400,
61670257200,
61685982000,
3600,
1,
'WEST'
    ],
    [
61685978400,
61701703200,
61685978400,
61701703200,
0,
0,
'WET'
    ],
    [
61701703200,
61718032800,
61701706800,
61718036400,
3600,
1,
'WEST'
    ],
    [
61718032800,
61733757600,
61718032800,
61733757600,
0,
0,
'WET'
    ],
    [
61733757600,
61749482400,
61733761200,
61749486000,
3600,
1,
'WEST'
    ],
    [
61749482400,
61765207200,
61749482400,
61765207200,
0,
0,
'WET'
    ],
    [
61765207200,
61780932000,
61765210800,
61780935600,
3600,
1,
'WEST'
    ],
    [
61780932000,
61796656800,
61780932000,
61796656800,
0,
0,
'WET'
    ],
    [
61796656800,
61812381600,
61796660400,
61812385200,
3600,
1,
'WEST'
    ],
    [
61812381600,
61828106400,
61812381600,
61828106400,
0,
0,
'WET'
    ],
    [
61828106400,
61843831200,
61828110000,
61843834800,
3600,
1,
'WEST'
    ],
    [
61843831200,
61859556000,
61843831200,
61859556000,
0,
0,
'WET'
    ],
    [
61859556000,
61875280800,
61859559600,
61875284400,
3600,
1,
'WEST'
    ],
    [
61875280800,
61891005600,
61875280800,
61891005600,
0,
0,
'WET'
    ],
    [
61891005600,
61907335200,
61891009200,
61907338800,
3600,
1,
'WEST'
    ],
    [
61907335200,
61923060000,
61907335200,
61923060000,
0,
0,
'WET'
    ],
    [
61923060000,
61938784800,
61923063600,
61938788400,
3600,
1,
'WEST'
    ],
    [
61938784800,
61954509600,
61938784800,
61954509600,
0,
0,
'WET'
    ],
    [
61954509600,
61970234400,
61954513200,
61970238000,
3600,
1,
'WEST'
    ],
    [
61970234400,
61985959200,
61970234400,
61985959200,
0,
0,
'WET'
    ],
    [
61985959200,
62001684000,
61985962800,
62001687600,
3600,
1,
'WEST'
    ],
    [
62001684000,
62017408800,
62001684000,
62017408800,
0,
0,
'WET'
    ],
    [
62017408800,
62348227200,
62017412400,
62348230800,
3600,
0,
'CET'
    ],
    [
62348227200,
62363952000,
62348227200,
62363952000,
0,
0,
'WET'
    ],
    [
62363952000,
62379676800,
62363955600,
62379680400,
3600,
1,
'WEST'
    ],
    [
62379676800,
62396006400,
62379676800,
62396006400,
0,
0,
'WET'
    ],
    [
62396006400,
62411731200,
62396010000,
62411734800,
3600,
1,
'WEST'
    ],
    [
62411731200,
62427456000,
62411731200,
62427456000,
0,
0,
'WET'
    ],
    [
62427456000,
62443184400,
62427459600,
62443188000,
3600,
1,
'WEST'
    ],
    [
62443184400,
62458905600,
62443184400,
62458905600,
0,
0,
'WET'
    ],
    [
62458905600,
62474634000,
62458909200,
62474637600,
3600,
1,
'WEST'
    ],
    [
62474634000,
62490358800,
62474634000,
62490358800,
0,
0,
'WET'
    ],
    [
62490358800,
62506083600,
62490362400,
62506087200,
3600,
1,
'WEST'
    ],
    [
62506083600,
62521808400,
62506083600,
62521808400,
0,
0,
'WET'
    ],
    [
62521808400,
62537533200,
62521812000,
62537536800,
3600,
1,
'WEST'
    ],
    [
62537533200,
62553261600,
62537533200,
62553261600,
0,
0,
'WET'
    ],
    [
62553261600,
62568982800,
62553265200,
62568986400,
3600,
1,
'WEST'
    ],
    [
62568982800,
62584707600,
62568982800,
62584707600,
0,
0,
'WET'
    ],
    [
62584707600,
62601037200,
62584711200,
62601040800,
3600,
1,
'WEST'
    ],
    [
62601037200,
62616762000,
62601037200,
62616762000,
0,
0,
'WET'
    ],
    [
62616762000,
62632486800,
62616765600,
62632490400,
3600,
1,
'WEST'
    ],
    [
62632486800,
62648211600,
62632486800,
62648211600,
0,
0,
'WET'
    ],
    [
62648211600,
62663936400,
62648215200,
62663940000,
3600,
1,
'WEST'
    ],
    [
62663936400,
62679661200,
62663936400,
62679661200,
0,
0,
'WET'
    ],
    [
62679661200,
62695386000,
62679664800,
62695389600,
3600,
1,
'WEST'
    ],
    [
62695386000,
62711110800,
62695386000,
62711110800,
0,
0,
'WET'
    ],
    [
62711110800,
62726835600,
62711114400,
62726839200,
3600,
1,
'WEST'
    ],
    [
62726835600,
62742560400,
62726835600,
62742560400,
0,
0,
'WET'
    ],
    [
62742560400,
62758285200,
62742564000,
62758288800,
3600,
1,
'WEST'
    ],
    [
62758285200,
62774010000,
62758285200,
62774010000,
0,
0,
'WET'
    ],
    [
62774010000,
62790339600,
62774013600,
62790343200,
3600,
1,
'WEST'
    ],
    [
62790339600,
62806064400,
62790339600,
62806064400,
0,
0,
'WET'
    ],
    [
62806064400,
62821789200,
62806068000,
62821792800,
3600,
1,
'WEST'
    ],
    [
62821789200,
62837514000,
62821789200,
62837514000,
0,
0,
'WET'
    ],
    [
62837514000,
62853238800,
62837517600,
62853242400,
3600,
1,
'WEST'
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
62963920800,
62982064800,
3600,
1,
'WEST'
    ],
    [
62982061200,
62995366800,
62982061200,
62995366800,
0,
0,
'WET'
    ],
    [
62995366800,
63013510800,
62995370400,
63013514400,
3600,
1,
'WEST'
    ],
    [
63013510800,
63026816400,
63013510800,
63026816400,
0,
0,
'WET'
    ],
    [
63026816400,
63044960400,
63026820000,
63044964000,
3600,
1,
'WEST'
    ],
    [
63044960400,
63058266000,
63044960400,
63058266000,
0,
0,
'WET'
    ],
    [
63058266000,
63077014800,
63058269600,
63077018400,
3600,
1,
'WEST'
    ],
    [
63077014800,
63089715600,
63077014800,
63089715600,
0,
0,
'WET'
    ],
    [
63089715600,
63108464400,
63089719200,
63108468000,
3600,
1,
'WEST'
    ],
    [
63108464400,
63121165200,
63108464400,
63121165200,
0,
0,
'WET'
    ],
    [
63121165200,
63139914000,
63121168800,
63139917600,
3600,
1,
'WEST'
    ],
    [
63139914000,
63153219600,
63139914000,
63153219600,
0,
0,
'WET'
    ],
    [
63153219600,
63171363600,
63153223200,
63171367200,
3600,
1,
'WEST'
    ],
    [
63171363600,
63184669200,
63171363600,
63184669200,
0,
0,
'WET'
    ],
    [
63184669200,
63202813200,
63184672800,
63202816800,
3600,
1,
'WEST'
    ],
    [
63202813200,
63216118800,
63202813200,
63216118800,
0,
0,
'WET'
    ],
    [
63216118800,
63234867600,
63216122400,
63234871200,
3600,
1,
'WEST'
    ],
    [
63234867600,
63247568400,
63234867600,
63247568400,
0,
0,
'WET'
    ],
    [
63247568400,
63266317200,
63247572000,
63266320800,
3600,
1,
'WEST'
    ],
    [
63266317200,
63279018000,
63266317200,
63279018000,
0,
0,
'WET'
    ],
    [
63279018000,
63297766800,
63279021600,
63297770400,
3600,
1,
'WEST'
    ],
    [
63297766800,
63310467600,
63297766800,
63310467600,
0,
0,
'WET'
    ],
    [
63310467600,
63329216400,
63310471200,
63329220000,
3600,
1,
'WEST'
    ],
    [
63329216400,
63342522000,
63329216400,
63342522000,
0,
0,
'WET'
    ],
    [
63342522000,
63360666000,
63342525600,
63360669600,
3600,
1,
'WEST'
    ],
    [
63360666000,
63373971600,
63360666000,
63373971600,
0,
0,
'WET'
    ],
    [
63373971600,
63392115600,
63373975200,
63392119200,
3600,
1,
'WEST'
    ],
    [
63392115600,
63405421200,
63392115600,
63405421200,
0,
0,
'WET'
    ],
    [
63405421200,
63424170000,
63405424800,
63424173600,
3600,
1,
'WEST'
    ],
    [
63424170000,
63436870800,
63424170000,
63436870800,
0,
0,
'WET'
    ],
    [
63436870800,
63455619600,
63436874400,
63455623200,
3600,
1,
'WEST'
    ],
    [
63455619600,
63468320400,
63455619600,
63468320400,
0,
0,
'WET'
    ],
    [
63468320400,
63487069200,
63468324000,
63487072800,
3600,
1,
'WEST'
    ],
    [
63487069200,
63500374800,
63487069200,
63500374800,
0,
0,
'WET'
    ],
    [
63500374800,
63518518800,
63500378400,
63518522400,
3600,
1,
'WEST'
    ],
    [
63518518800,
63531824400,
63518518800,
63531824400,
0,
0,
'WET'
    ],
    [
63531824400,
63549968400,
63531828000,
63549972000,
3600,
1,
'WEST'
    ],
    [
63549968400,
63563274000,
63549968400,
63563274000,
0,
0,
'WET'
    ],
    [
63563274000,
63581418000,
63563277600,
63581421600,
3600,
1,
'WEST'
    ],
    [
63581418000,
63594723600,
63581418000,
63594723600,
0,
0,
'WET'
    ],
    [
63594723600,
63613472400,
63594727200,
63613476000,
3600,
1,
'WEST'
    ],
];

sub _max_year { 2015 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}

sub _last_offset { 0 }

my $last_observance = bless( {
  'format' => 'WE%sT',
  'gmtoff' => '0:00',
  'local_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 728749,
    'local_rd_secs' => 7200,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 728749,
    'utc_rd_secs' => 7200,
    'utc_year' => 1997
  }, 'DateTime' ),
  'offset_from_std' => 0,
  'offset_from_utc' => 0,
  'until' => [],
  'utc_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 728749,
    'local_rd_secs' => 3600,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 728749,
    'utc_rd_secs' => 3600,
    'utc_year' => 1997
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
