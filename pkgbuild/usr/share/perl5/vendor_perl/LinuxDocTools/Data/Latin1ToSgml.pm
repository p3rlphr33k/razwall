#
#  Latin1ToSgml.pm
#
#  This is a latin1 only file containing functions having legacy
#  latin1 chars.  Split here to avoid the risk of messing up with
#  charsets in other files.
#
#  Copyright (C) 1995, Cees de Groot
#  Copyright (C) 1995, Farzad Farid
#  Copyright (C) 1995, Greg Hankins
#  Copyright (C) 2020, Agustin Martin
# ---------------------------------------------------------------------------

package LinuxDocTools::Data::Latin1ToSgml;

use strict;
use base qw(Exporter);
our @EXPORT_OK = qw(ldt_latin1tosgml);

# ---------------------------------------------------------------------------
sub ldt_latin1tosgml {
  # -------------------------------------------------------------------------
  # Convert latin1 chars in input filehandle to sgml entities in the
  # returned string (by Farzad Farid, adapted by Greg Hankins)
  # -------------------------------------------------------------------------
  my $FILE     = shift;
  my $sgmlout;

  while (<$FILE>){
    # Outline these commands later on - CdG
    # Upper Case Latin-1 Letters
    s/�/\&Agrave;/g; # &#192;
    s/�/\&Aacute;/g; # &#193;
    s/�/\&Acirc;/g;  # &#194;
    s/�/\&Atilde;/g; # &#195;
    s/�/\&Auml;/g;   # &#196;
    s/�/\&Aring;/g;  # &#197;
    s/�/\&AElig;/g;  # &#198;
    s/�/\&Ccedil;/g; # &#199;
    s/�/\&Egrave;/g; # &#200;
    s/�/\&Eacute;/g; # &#201;
    s/�/\&Ecirc;/g;  # &#202;
    s/�/\&Euml;/g;   # &#203;
    s/�/\&Igrave;/g; # &#204;
    s/�/\&Iacute;/g; # &#205;
    s/�/\&Icirc;/g;  # &#206;
    s/�/\&Iuml;/g;   # &#207;
    s/�/&ETH;/g;     # &#208;
    s/�/\&Ntilde;/g; # &#209;
    s/�/\&Ograve;/g; # &#210;
    s/�/\&Oacute;/g; # &#211;
    s/�/\&Ocirc;/g;  # &#212;
    s/�/\&Otilde;/g; # &#213;
    s/�/\&Ouml;/g;   # &#214;
    # s/�/&times;/g;   # &#215; Moved below to symbols
    s/�/\&Oslash;/g; # &#216;
    s/�/\&Ugrave;/g; # &#217;
    s/�/\&Uacute;/g; # &#218;
    s/�/\&Ucirc;/g;  # &#219;
    s/�/\&Uuml;/g;   # &#220;
    s/�/\&Yacute;/g; # &#221;
    s/�/\&THORN;/g;  # &#222;
    s/�/\&szlig;/g;  # &#223;
    # Lower Case Latin-1 Letters
    s/�/\&agrave;/g; # &#224;
    s/�/\&aacute;/g; # &#225;
    s/�/\&acirc;/g;  # &#226;
    s/�/\&atilde;/g; # &#227;
    s/�/\&auml;/g;   # &#228;
    s/�/\&aring;/g;  # &#229;
    s/�/\&aelig;/g;  # &#230;
    s/�/\&ccedil;/g; # &#231;
    s/�/\&egrave;/g; # &#232;
    s/�/\&eacute;/g; # &#233;
    s/�/\&ecirc;/g;  # &#234;
    s/�/\&euml;/g;   # &#235;
    s/�/\&igrave;/g; # &#236;
    s/�/\&iacute;/g; # &#237;
    s/�/\&icirc;/g;  # &#238;
    s/�/\&iuml;/g;   # &#239;
    s/�/\&eth;/g;    # &#240;
    s/�/\&ntilde;/g; # &#241;
    s/�/\&ograve;/g; # &#242;
    s/�/\&oacute;/g; # &#243;
    s/�/\&ocirc;/g;  # &#244;
    s/�/\&otilde;/g; # &#245;
    s/�/\&ouml;/g;   # &#246; #247 is divide symbol below
    s/�/\&oslash;/g; # &#248;
    s/�/\&ugrave;/g; # &#249;
    s/�/\&uacute;/g; # &#250;
    s/�/\&ucirc;/g;  # &#251;
    s/�/\&uuml;/g;   # &#252;
    s/�/\&yacute;/g; # &#253;
    s/�/\&thorn;/g;  # &#254;
    s/�/\&yuml;/g;   # &#255;
    # Some symbols
    s/�/&iexcl;/g;   # &#161;
    s/�/&cent;/g;    # &#162;
    s/�/&pound;/g;   # &#163;
    s/�/&curren;/g;  # &#164;
    s/�/&yen;/g;     # &#165;
    s/�/&brkbar;/g;  # &#166;
    s/�/&sect;/g;    # &#167;
    s/�/&copy;/g;    # &#169;
    s/�/&laquo;/g;   # &#171;
    s/�/&not;/g;     # &#172;
    s/�/&reg;/g;     # &#174;
    s/�/&deg;/g;     # &#176;
    s/�/&plusmn;/g;  # &#177;
    s/�/\&mu;/g;     # &#181;
    s/�/&iquest;/g;  # &#191;
    s/�/&times;/g;   # &#215;
    s/�/&divide;/g;  # &#247;
    $sgmlout .= $_;
  }
  return $sgmlout;
}

1;

__END__

# Local Variables:
# coding: iso-8859-1
# perl-indent-level: 2
# End:
