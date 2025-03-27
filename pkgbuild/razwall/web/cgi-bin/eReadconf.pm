package eReadconf;

#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2006 Endian                                              |
#        |         Endian GmbH/Srl                                                     |
#        |         Bergweg 41 Via Monte                                                |
#        |         39057 Eppan/Appiano                                                 |
#        |         ITALIEN/ITALIA                                                      |
#        |         info@endian.it                                                      |
#        |                                                                             |
#        | This program is free software; you can redistribute it and/or               |
#        | modify it under the terms of the GNU General Public License                 |
#        | as published by the Free Software Foundation; either version 2              |
#        | of the License, or (at your option) any later version.                      |
#        |                                                                             |
#        | This program is distributed in the hope that it will be useful,             |
#        | but WITHOUT ANY WARRANTY; without even the implied warranty of              |
#        | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               |
#        | GNU General Public License for more details.                                |
#        |                                                                             |
#        | You should have received a copy of the GNU General Public License           |
#        | along with this program; if not, write to the Free Software                 |
#        | Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. |
#        | http://www.fsf.org/                                                         |
#        +-----------------------------------------------------------------------------+
#
use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(readconf writeconf);
1;

# -----------------------------------------------------------
# $hashref = readconf("fname"):
#    returns a hashref with the key/val pairs defined
#    in the properties-style configuration file "fname"
# -----------------------------------------------------------
sub readconf
{
  my $fname = shift;
  my $line;
  my %conf;
  open(IN, $fname) or die("cannot open settings file '$fname', because '$!'");
  while ($line = <IN>) {
    next if ($line =~ /^\s*$/ or $line =~ /^\s*#/);
    if ($line =~ /^\s*(.+)\s*=\s*(.+)/) {
      $conf{$1} = $2;
    }
  }
  close(IN);
  return \%conf;
}


# -----------------------------------------------------------
# writeconf($filename, $hash_ref):
# writes down all items of the hash in hash_ref to the file filename
# -----------------------------------------------------------
sub writeconf($$) {
    my $filename = shift;
    my $hash_ref = shift;

    if (-e $filename) {
        system("cp -f $filename ${filename}.old &>/dev/null");
    }

    open(OUT, '>'.$filename) or die("cannot open file \"$filename\" for writing.");
    foreach $key (sort(keys(%$hash_ref))) {
	print(OUT "$key=".$hash_ref->{$key}."\n");
    }
    close(OUT);
}

