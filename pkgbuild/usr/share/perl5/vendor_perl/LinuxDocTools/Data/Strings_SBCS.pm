#
#  Strings_SBCS.pm
#
#  Language support. Single Byte Character Set strings translations.
#
# The module, in its source file, contains a data structure, indexed
# by the English strings, that has all available single byte
# translations.
#
# Be careful, this file mixes different single byte encodings, latin1,
# euc-jp and euc-kr.
#
# For UTF-8 translations of strings look at Data::Strings_UTF8.pm
#
# By the time this grows big, we'll make up something else.
#
#  Copyright (C) 1997, Cees de Groot
#  Copyright (C) 2020, Agustin Martin
# -------------------------------------------------------------------------

package LinuxDocTools::Data::Strings_SBCS;

use strict;

our $translations
  = {
     "Previous"
     => {
	 "nl" => "Terug",
	 "de" => "Zur�ck",
	 "es" => "P�gina anterior",
	 "fr" => "Page pr�c�dente",
	 "da" => "Forrige",
	 "no" => "Forrige",
	 "se" => "F�reg�ende",
	 "pt" => "P�gina anterior",
	 "ca" => "P�gina anterior",
	 "it" => "Indietro",
	 "ro" => "�napoi",
	 "ja" => "���Υڡ���",
	 "pl" => "Poprzedni",
	 "ko" => "����",
	 "fi" => "Edellinen"
	},
     "Next"
     => {
	 "nl" => "Verder",
	 "de" => "Weiter",
	 "es" => "P�gina siguiente",
	 "fr" => "Page suivante",
	 "da" => "N�ste",
	 "no" => "Neste",
	 "se" => "N�sta",
	 "pt" => "P�gina seguinte",
	 "ca" => "P�gina seg�ent",
	 "it" => "Avanti",
	 "ro" => "�nainte",
	 "ja" => "���Υڡ���",
	 "pl" => "Nastny",
	 "ko" => "����",
	 "fi" => "Seuraava"
	},
     "Contents"
     => {
	 "nl" => "Inhoud",
	 "de" => "Inhalt",
	 "es" => "�ndice general",
	 "fr" => "Table des mati�res",
	 "da" => "Indhold",
	 "no" => "Innhold",
	 "se" => "Inneh�llsf�rteckning",
	 "pt" => "�ndice",
	 "ca" => "�ndex",
	 "it" => "Indice",
	 "ro" => "Cuprins",
	 "ja" => "�ܼ���",
	 "pl" => "Spis Trei",
	 "ko" => "����",
	 "fi" => "Sis�llys"
	},
     "Table of Contents"
     => {
	 "nl" => "Inhoudsopgave",
	 "de" => "Inhaltsverzeichnis",
	 "es" => "�ndice general",
	 "fr" => "Table des mati�res",
	 "da" => "Indholdsfortegnelse",
	 "no" => "Innholdsfortegnelse",
	 "se" => "Inneh�llsf�rteckning",
	 "pt" => "�ndice geral",
	 "ca" => "�ndex general",
	 "it" => "Indice Generale",
	 "ro" => "Cuprins",
	 "ja" => "�ܼ�",
	 "pl" => "Spis Trei",
	 "ko" => "����",
	 "fi" => "Sis�llysluettelo"
	}
    };

=back

=head1 AUTHOR

Cees de Groot, C<E<lt>cg@pobox.comE<gt>>

=cut

1;
