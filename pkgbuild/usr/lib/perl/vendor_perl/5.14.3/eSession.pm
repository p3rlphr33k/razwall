package eSession;
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
@EXPORT = qw(session_start session_check session_save session_load session_end);
1;

sub session_start
{
  my $id = int(rand() * 100000000 + 100000000);
  open (OUT, ">/tmp/$id") or die();
  close OUT;
  chmod 0600, "/tmp/$id";
  return $id;
}

sub session_check
{
  my $id = shift;
  unless ($id =~ /^\d+$/) {
    return 0;
  }
  unless (-f "/tmp/$id") {
    return 0;
  }
  return 1;
}

sub session_save
{
  my $id   = shift;
  my $href = shift;
  open (OUT, ">/tmp/$id") or die();
  foreach my $key (keys(%$href)) {
    print OUT "$key=" . $$href{$key} . "\n";
  }  
  close OUT;
  return;
}

sub session_load
{
  my $id = shift;
  my $href = shift;
  open(IN, "/tmp/$id") or die();
  while ($line = <IN>) {
    next if ($line =~ /^\s*$/ or $line =~ /^\s*#/);
    if ($line =~ /^\s*(.+)\s*=\s*(.+)/) {
      $href->{$1} = $2;
    }
  }
  close(IN);
  return;
}

sub session_stop
{
  my $id = int(rand() * 100000000 + 100000000);
  open (OUT, ">/tmp/$id") or die();
  close OUT;
  chmod 0600, "/tmp/$id";
  return $id;
}


