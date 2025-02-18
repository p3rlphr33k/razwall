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
# This file was generated from the source file be.xml.
# The source file version number was 1.2, generated on
# 2004-08-27.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::be;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::root;

@DateTime::Locale::be::ISA = qw(DateTime::Locale::root);

my @day_names = (
"панядзелак",
"аўторак",
"серада",
"чацвер",
"пятніца",
"субота",
"нядзеля",
);

my @day_abbreviations = (
"пн",
"аў",
"ср",
"чц",
"пт",
"сб",
"нд",
);

my @month_names = (
"студзень",
"люты",
"сакавік",
"красавік",
"май",
"чэрвень",
"ліпень",
"жнівень",
"верасень",
"кастрычнік",
"лістапад",
"снежань",
);

my @month_abbreviations = (
"сту",
"лют",
"сак",
"кра",
"май",
"чэр",
"ліп",
"жні",
"вер",
"кас",
"ліс",
"сне",
);

my @eras = (
"да\ н\.е\.",
"н\.е\.",
);

my $date_parts_order = "dmy";


sub day_names                      { \@day_names }
sub day_abbreviations              { \@day_abbreviations }
sub month_names                    { \@month_names }
sub month_abbreviations            { \@month_abbreviations }
sub eras                           { \@eras }
sub full_date_format               { "\%A\,\ \%\{day\}\ \%B\ \%\{ce_year\}" }
sub long_date_format               { "\%\{day\}\ \%B\ \%\{ce_year\}" }
sub medium_date_format             { "\%\{day\}\.\%\{month\}\.\%\{ce_year\}" }
sub short_date_format              { "\%\{day\}\.\%\{month\}\.\%y" }
sub full_time_format               { "\%H\.\%M\.\%S\ \%\{time_zone_long_name\}" }
sub long_time_format               { "\%H\.\%M\.\%S\ \%\{time_zone_long_name\}" }
sub medium_time_format             { "\%H\.\%M\.\%S" }
sub short_time_format              { "\%H\.\%M" }
sub date_parts_order               { $date_parts_order }



1;

