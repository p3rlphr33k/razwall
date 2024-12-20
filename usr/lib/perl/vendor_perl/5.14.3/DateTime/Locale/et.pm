###########################################################################
#
# This file is auto-generated by the Perl DateTime Suite time locale
# generator (0.02).  This code generator comes with the
# DateTime::Locale distribution in the tools/ directory, and is called
# generate_from_icu.
#
# This file as generated from the ICU XML locale data.  See the
# LICENSE.icu file included in this distribution for license details.
#
# This file was generated from the source file et.xml.
# The source file version number was 1.2, generated on
# 2004-08-27.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::et;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::root;

@DateTime::Locale::et::ISA = qw(DateTime::Locale::root);

my @day_names = (
"esmaspäev",
"teisipäev",
"kolmapäev",
"neljapäev",
"reede",
"laupäev",
"pühapäev",
);

my @day_abbreviations = (
"E",
"T",
"K",
"N",
"R",
"L",
"P",
);

my @month_names = (
"jaanuar",
"veebruar",
"märts",
"aprill",
"mai",
"juuni",
"juuli",
"august",
"september",
"oktoober",
"november",
"detsember",
);

my @month_abbreviations = (
"jaan",
"veebr",
"märts",
"apr",
"mai",
"juuni",
"juuli",
"aug",
"sept",
"okt",
"nov",
"dets",
);

my @eras = (
"e\.m\.a\.",
"m\.a\.j\.",
);

my $date_parts_order = "dmy";


sub day_names                      { \@day_names }
sub day_abbreviations              { \@day_abbreviations }
sub month_names                    { \@month_names }
sub month_abbreviations            { \@month_abbreviations }
sub eras                           { \@eras }
sub full_date_format               { "\%A\,\ \%\{day\}\,\ \%B\ \%\{ce_year\}" }
sub long_date_format               { "\%\{day\}\ \%B\ \%\{ce_year\}" }
sub medium_date_format             { "\%d\.\%m\.\%\{ce_year\}" }
sub short_date_format              { "\%d\.\%m\.\%y" }
sub full_time_format               { "\%\{hour\}\:\%M\:\%S\ \%\{time_zone_long_name\}" }
sub long_time_format               { "\%\{hour\}\:\%M\:\%S\ \%\{time_zone_long_name\}" }
sub medium_time_format             { "\%\{hour\}\:\%M\:\%S" }
sub short_time_format              { "\%\{hour\}\:\%M" }
sub date_parts_order               { $date_parts_order }



1;

