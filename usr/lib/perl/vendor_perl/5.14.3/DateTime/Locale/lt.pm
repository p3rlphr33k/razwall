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
# This file was generated from the source file lt.xml.
# The source file version number was 1.2, generated on
# 2004-08-27.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::lt;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::root;

@DateTime::Locale::lt::ISA = qw(DateTime::Locale::root);

my @day_names = (
"Pirmadienis",
"Antradienis",
"Trečiadienis",
"Ketvirtadienis",
"Penktadienis",
"Šeštadienis",
"Sekmadienis",
);

my @day_abbreviations = (
"Pr",
"An",
"Tr",
"Kt",
"Pn",
"Št",
"Sk",
);

my @month_names = (
"Sausio",
"Vasario",
"Kovo",
"Balandžio",
"Gegužės",
"Birželio",
"Liepos",
"Rugpjūčio",
"Rugsėjo",
"Spalio",
"Lapkričio",
"Gruodžio",
);

my @month_abbreviations = (
"Sau",
"Vas",
"Kov",
"Bal",
"Geg",
"Bir",
"Lie",
"Rgp",
"Rgs",
"Spa",
"Lap",
"Grd",
);

my @eras = (
"pr\.Kr\.",
"po\.Kr\.",
);

my $date_parts_order = "ymd";


sub day_names                      { \@day_names }
sub day_abbreviations              { \@day_abbreviations }
sub month_names                    { \@month_names }
sub month_abbreviations            { \@month_abbreviations }
sub eras                           { \@eras }
sub full_date_format               { "\%\{ce_year\}\ m\.\ \%B\ \%\{day\}\ d\.\,\%A" }
sub long_date_format               { "\%\{ce_year\}\ m\.\ \%B\ \%\{day\}\ d\." }
sub medium_date_format             { "\%\{ce_year\}\.\%m\.\%d" }
sub short_date_format              { "\%\{ce_year\}\.\%m\.\%d" }
sub date_parts_order               { $date_parts_order }



1;

