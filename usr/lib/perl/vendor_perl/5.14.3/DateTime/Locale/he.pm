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
# This file was generated from the source file he.xml.
# The source file version number was 1.2, generated on
# 2004-08-27.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::he;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::root;

@DateTime::Locale::he::ISA = qw(DateTime::Locale::root);

my @day_names = (
"יום\ שני",
"יום\ שלישי",
"יום\ רביעי",
"יום\ חמישי",
"יום\ שישי",
"שבת",
"יום\ ראשון",
);

my @day_abbreviations = (
"ב",
"ג",
"ד",
"ה",
"ו",
"ש",
"א",
);

my @day_narrows = (
"ב",
"ג",
"ד",
"ה",
"ו",
"ש",
"א",
);

my @month_names = (
"ינואר",
"פברואר",
"מרץ",
"אפריל",
"מאי",
"יוני",
"יולי",
"אוגוסט",
"ספטמבר",
"אוקטובר",
"נובמבר",
"דצמבר",
);

my @month_abbreviations = (
"ינו",
"פבר",
"מרץ",
"אפר",
"מאי",
"יונ",
"יול",
"אוג",
"ספט",
"אוק",
"נוב",
"דצמ",
);

my @eras = (
"לפנה״ס",
"לסה״נ",
);

my $date_parts_order = "dmy";


sub day_names                      { \@day_names }
sub day_abbreviations              { \@day_abbreviations }
sub day_narrows                    { \@day_narrows }
sub month_names                    { \@month_names }
sub month_abbreviations            { \@month_abbreviations }
sub eras                           { \@eras }
sub full_date_format               { "\%A\ \%\{day\}\ \%B\ \%\{ce_year\}" }
sub long_date_format               { "\%\{day\}\ \%B\ \%\{ce_year\}" }
sub medium_date_format             { "\%d\/\%m\/\%\{ce_year\}" }
sub short_date_format              { "\%d\/\%m\/\%y" }
sub date_parts_order               { $date_parts_order }



1;

