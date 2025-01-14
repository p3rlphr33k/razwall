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
# This file was generated from the source file wal_ET.xml.
# The source file version number was 1.2, generated on
# 2004-06-04.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::wal_ET;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::wal;

@DateTime::Locale::wal_ET::ISA = qw(DateTime::Locale::wal);

my $date_parts_order = "dmy";


sub full_date_format               { "\%A፥\ \%d\ \%B\ ጋላሳ\ \%\{ce_year\}\ \%\{era\}" }
sub long_date_format               { "\%d\ \%B\ \%\{ce_year\}" }
sub medium_date_format             { "\%d\-\%b\-\%\{ce_year\}" }
sub short_date_format              { "\%d\/\%m\/\%y" }
sub full_time_format               { "\%\{hour_12\}\:\%M\:\%S\ \%p" }
sub long_time_format               { "\%\{hour_12\}\:\%M\:\%S\ \%p" }
sub medium_time_format             { "\%\{hour_12\}\:\%M\:\%S\ \%p" }
sub short_time_format              { "\%\{hour_12\}\:\%M\ \%p" }
sub date_parts_order               { $date_parts_order }



1;

