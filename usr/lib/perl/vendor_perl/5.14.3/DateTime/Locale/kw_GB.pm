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
# This file was generated from the source file kw_GB.xml.
# The source file version number was 1.2, generated on
# 2004-08-27.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::kw_GB;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::kw;

@DateTime::Locale::kw_GB::ISA = qw(DateTime::Locale::kw);

my $date_parts_order = "dmy";


sub full_date_format               { "\%A\ \%\{day\}\ \%B\ \%\{ce_year\}" }
sub long_date_format               { "\%\{day\}\ \%B\ \%\{ce_year\}" }
sub medium_date_format             { "\%\{day\}\ \%b\ \%\{ce_year\}" }
sub short_date_format              { "\%d\/\%m\/\%\{ce_year\}" }
sub long_time_format               { "\%H\:\%M\:\%S" }
sub date_parts_order               { $date_parts_order }



1;

