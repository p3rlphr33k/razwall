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
# This file was generated from the source file bg.xml.
# The source file version number was 1.2, generated on
# 2004-08-27.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::bg;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::root;

@DateTime::Locale::bg::ISA = qw(DateTime::Locale::root);

my @day_names = (
"понеделник",
"вторник",
"сряда",
"четвъртък",
"петък",
"събота",
"неделя",
);

my @day_abbreviations = (
"пон\.",
"вт\.",
"ср\.",
"четв\.",
"пет\.",
"съб\.",
"нед\.",
);

my @day_narrows = (
"п",
"в",
"с",
"ч",
"п",
"с",
"н",
);

my @month_names = (
"януари",
"февруари",
"март",
"април",
"май",
"юни",
"юли",
"август",
"септември",
"октомври",
"ноември",
"декември",
);

my @month_abbreviations = (
"ян\.",
"фев\.",
"март",
"апр\.",
"май",
"юни",
"юли",
"авг\.",
"сеп\.",
"окт\.",
"ноем\.",
"дек\.",
);

my @month_narrows = (
"я",
"ф",
"м",
"а",
"м",
"ю",
"ю",
"а",
"с",
"о",
"н",
"д",
);

my @eras = (
"пр\.н\.е\.",
"н\.е\.",
);

my $date_parts_order = "dmy";


sub day_names                      { \@day_names }
sub day_abbreviations              { \@day_abbreviations }
sub day_narrows                    { \@day_narrows }
sub month_names                    { \@month_names }
sub month_abbreviations            { \@month_abbreviations }
sub month_narrows                  { \@month_narrows }
sub eras                           { \@eras }
sub full_date_format               { "\%d\ \%B\ \%\{ce_year\}\,\ \%A" }
sub long_date_format               { "\%d\ \%B\ \%\{ce_year\}" }
sub medium_date_format             { "\%d\.\%m\.\%\{ce_year\}" }
sub short_date_format              { "\%d\.\%m\.\%y" }
sub long_time_format               { "\%H\:\%M\:\%S" }
sub date_parts_order               { $date_parts_order }



1;

