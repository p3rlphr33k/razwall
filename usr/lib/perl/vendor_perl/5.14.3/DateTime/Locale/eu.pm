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
# This file was generated from the source file eu.xml.
# The source file version number was 1.2, generated on
# 2004-08-27.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::eu;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::root;

@DateTime::Locale::eu::ISA = qw(DateTime::Locale::root);

my @day_names = (
"astelehena",
"asteartea",
"asteazkena",
"osteguna",
"ostirala",
"larunbata",
"igandea",
);

my @day_abbreviations = (
"al",
"as",
"az",
"og",
"or",
"lr",
"ig",
);

my @month_names = (
"urtarrila",
"otsaila",
"martxoa",
"apirila",
"maiatza",
"ekaina",
"uztaila",
"abuztua",
"iraila",
"urria",
"azaroa",
"abendua",
);

my @month_abbreviations = (
"urt",
"ots",
"mar",
"api",
"mai",
"eka",
"uzt",
"abu",
"ira",
"urr",
"aza",
"abe",
);



sub day_names                      { \@day_names }
sub day_abbreviations              { \@day_abbreviations }
sub month_names                    { \@month_names }
sub month_abbreviations            { \@month_abbreviations }



1;
