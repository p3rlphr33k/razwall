package SGMLS;
use Carp;

$version = '$Revision: 1.14 $';

=head1 NAME

SGMLS - class for postprocessing the output from the B<onsgmls>, B<sgmls>, and
B<nsgmls> parsers.

=head1 SYNOPSIS

  use SGMLS;

  my $parse = new SGMLS(STDIN);

  my $event = $parse->next_event;
  while ($event) {

    SWITCH: {

      ($event->type eq 'start_element') && do {
        my $element = $event->data;    # An object of class SGMLS_Element
        [[your code for the beginning of an element]]
        last SWITCH;
      };

      ($event->type eq 'end_element') && do {
        my $element = $event->data;    # An object of class SGMLS_Element
        [[your code for the end of an element]]
        last SWITCH;
      };

      ($event->type eq 'cdata') && do {
        my $cdata = $event->data;      # A string
        [[your code for character data]]
        last SWITCH;
      };

      ($event->type eq 'sdata') && do {
        my $sdata = $event->data;      # A string
        [[your code for system data]]
        last SWITCH;
      };

      ($event->type eq 're') && do {
        [[your code for a record end]]
        last SWITCH;
      };

      ($event->type eq 'pi') && do {
        my $pi = $event->data;         # A string
        [[your code for a processing instruction]]
        last SWITCH;
      };

      ($event->type eq 'entity') && do {
        my $entity = $event->data;     # An object of class SGMLS_Entity
        [[your code for an external entity]]
        last SWITCH;
      };

      ($event->type eq 'start_subdoc') && do {
        my $entity = $event->data;     # An object of class SGMLS_Entity
        [[your code for the beginning of a subdoc entity]]
        last SWITCH;
      };

      ($event->type eq 'end_subdoc') && do {
        my $entity = $event->data;     # An object of class SGMLS_Entity
        [[your code for the end of a subdoc entity]]
        last SWITCH;
      };

      ($event->type eq 'conforming') && do {
        [[your code for a conforming document]]
        last SWITCH;
      };

      die "Internal error: unknown event type " . $event->type . "\n";
    }

    $event = $parse->next_event;
  }

=head1 DESCRIPTION

The B<SGMLS> package consists of several related classes: see
L<"SGMLS">, L<"SGMLS_Event">, L<"SGMLS_Element">,
L<"SGMLS_Attribute">, L<"SGMLS_Notation">, and L<"SGMLS_Entity">.  All
of these classes are available when you specify

  use SGMLS;

Generally, the only object which you will create explicitly will
belong to the C<SGMLS> class; all of the others will then be created
automatically for you over the course of the parse.  Much fuller
documentation is available in the C<.sgml> files in the C<DOC/>
directory of the C<SGMLS.pm> distribution.

=head2 The C<SGMLS> class

This class holds a single parse.  When you create an instance of it,
you specify a file handle as an argument (if you are reading the
output of B<onsgmls>, B<sgmls> or B<nsgmls> from a pipe, the file handle will
ordinarily be C<STDIN>):

  my $parse = new SGMLS(STDIN);

The most important method for this class is C<next_event>, which reads
and returns the next major event from the input stream.  It is
important to note that the C<SGMLS> class deals with most B<ESIS>
events itself: attributes and entity definitions, for example, are
collected and stored automatically and invisibly to the user.  The
following list contains all of the methods for the C<SGMLS> class:

=over

=item C<next_event()>: Return an C<SGMLS_Event> object containing the
next major event from the SGML parse.

=item C<element()>: Return an C<SGMLS_Element> object containing the
current element in the document.

=item C<file()>: Return a string containing the name of the current
SGML source file (this will work only if the C<-l> option was given to
B<onsgmls>, B<sgmls> or B<nsgmls>).

=item C<line()>: Return a string containing the current line number
from the source file (this will work only if the C<-l> option was
given to B<onsgmls>, B<sgmls> or B<nsgmls>).

=item C<appinfo()>: Return a string containing the C<APPINFO>
parameter (if any) from the SGML declaration.

=item C<notation(NNAME)>: Return an C<SGMLS_Notation> object
representing the notation named C<NNAME>.  With newer versions of
B<nsgmls>, all notations are available; otherwise, only the notations
which are actually used will be available.

=item C<entity(ENAME)>: Return an C<SGMLS_Entity> object representing
the entity named C<ENAME>.  With newer versions of B<nsgmls>, all
entities are available; otherwise, only external data entities and
internal entities used as attribute values will be available.

=item C<ext()>: Return a reference to an associative array for
user-defined extensions.

=back

=head2 The C<SGMLS_Event> class

This class holds a single major event, as generated by the
C<next_event> method in the C<SGMLS> class.  It uses the following
methods:

=over

=item C<type()>: Return a string describing the type of event:
"start_element", "end_element", "cdata", "sdata", "re", "pi",
"entity", "start_subdoc", "end_subdoc", and "conforming".  See
L<"SYNOPSIS">, above, for the values associated with each of these.

=item C<data()>: Return the data associated with the current event (if
any).  For "start_element" and "end_element", returns an
C<SGMLS_ELement> object; for "entity", "start_subdoc", and
"end_subdoc", returns an C<SGMLS_Entity> object; for "cdata", "sdata",
and "pi", returns a string; and for "re" and "conforming", returns the
empty string.  See L<"SYNOPSIS">, above, for an example of this
method's use.

=item C<key()>: Return a string key to the event, such as an element
or entity name (otherwise, the same as C<data()>).

=item C<file()>: Return the current file name, as in the C<SGMLS>
class.

=item C<line()>: Return the current line number, as in the C<SGMLS>
class.

=item C<element()>: Return the current element, as in the C<SGMLS>
class.

=item C<parse()>: Return the C<SGMLS> object which generated the
event.

=item C<entity(ENAME)>: Look up an entity, as in the C<SGMLS> class.

=item C<notation(ENAME)>: Look up a notation, as in the C<SGMLS>
class.

=item C<ext()>: Return a reference to an associative array for
user-defined extensions.

=back

=head2 The C<SGMLS_Element> class

This class is used for elements, and contains all associated
information (such as the element's attributes).  It recognises the
following methods:

=over

=item C<name()>: Return a string containing the name, or Generic
Identifier, of the element, in upper case.

=item C<parent()>: Return the C<SGMLS_Element> object for the
element's parent (if any).

=item C<parse()>: Return the C<SGMLS> object for the current parse.

=item C<attributes()>: Return a reference to an associative array of
attribute names and C<SGMLS_Attribute> structures.  Attribute names
will be all in upper case.

=item C<attribute_names()>: Return an array of strings containing the
names of all attributes defined for the current element, in upper
case.

=item C<attribute(ANAME)>: Return the C<SGMLS_Attribute> structure for
the attribute C<ANAME>.

=item C<set_attribute(ATTRIB)>: Add the C<SGMLS_Attribute> object
C<ATTRIB> to the current element, replacing any other attribute
structure with the same name.

=item C<in(GI)>: Return C<true> (ie. 1) if the string C<GI> is the
name of the current element's parent, or C<false> (ie. 0) if it is
not.

=item C<within(GI)>: Return C<true> (ie. 1) if the string C<GI> is the
name of any of the ancestors of the current element, or C<false>
(ie. 0) if it is not.

=item C<ext()>: Return a reference to an associative array for
user-defined extensions.

=back

=head2 The C<SGMLS_Attribute> class

Each instance of an attribute for each C<SGMLS_Element> is an object
belonging to this class, which recognises the following methods:

=over

=item C<name()>: Return a string containing the name of the current
attribute, all in upper case.

=item C<type()>: Return a string containing the type of the current
attribute, all in upper case.  Available types are "IMPLIED", "CDATA",
"NOTATION", "ENTITY", and "TOKEN".

=item C<value()>: Return the value of the current attribute, if any.
This will be an empty string if the type is "IMPLIED", a string of
some sort if the type is "CDATA" or "TOKEN" (if it is "TOKEN", you may
want to split the string into a series of separate tokens), an
C<SGMLS_Notation> object if the type is "NOTATION", or an
C<SGMLS_Entity> object if the type is "ENTITY".  Note that if the
value is "CDATA", it will I<not> have escape sequences for 8-bit
characters, record ends, or SDATA processed -- that will be your
responsibility.

=item C<is_implied()>: Return C<true> (ie. 1) if the value of the
attribute is implied, or C<false> (ie. 0) if it is specified in the
document.

=item C<set_type(TYPE)>: Change the type of the attribute to the
string C<TYPE> (which should be all in upper case).  Available types
are "IMPLIED", "CDATA", "NOTATION", "ENTITY", and "TOKEN".

=item C<set_value(VALUE)>: Change the value of the attribute to
C<VALUE>, which may be a string, an C<SGMLS_Entity> object, or an
C<SGMLS_Notation> subject, depending on the attribute's type.

=item C<ext()>: Return a reference to an associative array available
for user-defined extensions.

=back

=head2 The C<SGMLS_Notation> class

All declared notations appear as objects belonging to this class,
which recognises the following methods:

=over

=item C<name()>: Return a string containing the name of the notation.

=item C<sysid()>: Return a string containing the system identifier of
the notation, if any.

=item C<pubid()>: Return a string containing the public identifier of
the notation, if any.

=item C<ext()>: Return a reference to an associative array available
for user-defined extensions.

=back

=head2 The C<SGMLS_Entity> class

All declared entities appear as objects belonging to this class, which
recognises the following methods:

=over

=item C<name()>: Return a string containing the name of the entity, in
mixed case.

=item C<type()>: Return a string containing the type of the entity, in
upper case.  Available types are "CDATA", "SDATA", "NDATA" (external
entities only), "SUBDOC", "PI" (newer versions of B<nsgmls> only), or
"TEXT" (newer versions of B<nsgmls> only).

=item C<value()>: Return a string containing the value of the entity,
if it is internal.

=item C<sysid()>: Return a string containing the system identifier of
the entity (if any), if it is external.

=item C<pubid()>: Return a string containing the public identifier of
the entity (if any), if it is external.

=item C<filenames()>: Return an array of strings containing any file
names generated from the identifiers, if the entity is external.

=item C<notation()>: Return the C<SGMLS_Notation> object associated
with the entity, if it is external.

=item C<data_attributes()>: Return a reference to an associative array
of data attribute names (in upper case) and the associated
C<SGMLS_Attribute> objects for the current entity.

=item C<data_attribute_names()>: Return an array of data attribute
names (in upper case) for the current entity.

=item C<data_attribute(ANAME)>: Return the C<SGMLS_Attribute> object
for the data attribute named C<ANAME> for the current entity.

=item C<set_data_attribute(ATTRIB)>: Add the C<SGMLS_Attribute> object
C<ATTRIB> to the current entity, replacing any other data attribute
with the same name.

=item C<ext()>: Return a reference to an associative array for
user-defined extensions.

=back

=head1 AUTHOR AND COPYRIGHT

Copyright 1994 and 1995 by David Megginson,
C<dmeggins@aix1.uottawa.ca>.  Distributed under the terms of the Gnu
General Public License (version 2, 1991) -- see the file C<COPYING>
which is included in the B<SGMLS.pm> distribution.


=head1 SEE ALSO:

L<SGMLS::Output> and L<SGMLS::Refs>.

=cut

#
# Data class for a single SGMLS ESIS output event.  The object will
# keep information about its own current element and, if available,
# the source file and line where the event appeared.
#
# Event types are as follow:
#        Event                 Data
# -------------------------------------------------------
#     'start_element'        SGMLS_Element
#     'end_element'          SGMLS_Element
#     'cdata'                string
#     'sdata'                string
#     're'                   [none]
#     'pi'                   string
#     'entity'               SGMLS_Entity
#     'start_subdoc'         SGMLS_Entity
#     'end_subdoc'           SGMLS_Entity
#     'conforming'           [none]
#
package SGMLS_Event;
use Carp;
				# Constructor.
sub new {
    my ($class,$type,$data,$parse) = @_;
    return bless [$type,
		  $data,
		  $parse->file,
		  $parse->line,
		  $parse->element,
		  $parse,
		  {}
		  ];
}
				# Accessors.
sub type { return $_[0]->[0]; }
sub data { return $_[0]->[1]; }
sub file { return $_[0]->[2]; }
sub line { return $_[0]->[3]; }
sub element { return $_[0]->[4]; }
sub parse { return $_[0]->[5]; }
sub ext { return $_[0]->[6]; }
				# Generate a key for the event.
sub key {
    my $self = shift;
    if (ref($self->data) eq SGMLS_Element ||
	ref($self->data) eq SGMLS_Entity) {
	return $self->data->name;
    } else {
	return $self->data;
    }
}
				# Look up an entity in the parse.
sub entity {
    my ($self,$ename) = (@_);
    return $self->parse->entity($ename);
}
				# Look up a notation in the parse.
sub notation {
    my ($self,$nname) = (@_);
    return $self->parse->notation($nname);
}
    

#
# Data class for a single SGML attribute.  The object will know its
# type, and will keep a value unless the type is 'IMPLIED', in which
# case no meaningful value is available.
#
# Attribute types are as follow:
#      Type                    Value
# ---------------------------------------
#     IMPLIED                 [none]
#     CDATA                   string
#     NOTATION                SGMLS_Notation
#     ENTITY                  SGMLS_Entity
#     TOKEN                   string
#
package SGMLS_Attribute;
use Carp;
				# Constructor.
sub new {
    my ($class,$name,$type,$value) = @_;
    return bless [$name,$type,$value,{}];
}
				# Accessors.
sub name { return $_[0]->[0]; }
sub type { return $_[0]->[1]; }
sub value { return $_[0]->[2]; }
sub ext { return $_[0]->[3]; }
				# Return 1 if the value is implied.
sub is_implied {
    my $self = shift;
    return ($self->type eq 'IMPLIED');
}
				# Set the attribute's type.
sub set_type {
    my ($self,$type) = @_;
    $self->[1] = $type;
}

				# Set the attribute's value.
sub set_value {
    my ($self,$value) = @_;
    $self->[2] = $value;
}


#
# Data class for a single element of an SGML document.  The object will not
# know about its children (data or other elements), but it keeps track of its
# parent and its attributes.
#
package SGMLS_Element;
use Carp;
				# Constructor.
sub new {
    my ($class,$name,$parent,$attributes,$parse) = @_;
    return bless [$name,$parent,$attributes,$parse,{}];
}
				# Accessors.
sub name { return $_[0]->[0]; }
sub parent { return $_[0]->[1]; }
sub parse { return $_[0]->[3]; }
sub ext { return $_[0]->[4]; }

				# Return the associative array of
				# attributes, parsing it the first
				# time through.
sub attributes {
    my $self = shift;
    if (ref($self->[2]) eq 'ARRAY') {
	my $new = {};
	foreach (@{$self->[2]}) {
	    /^(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
		|| croak "Bad attribute event data: $_";
	    my ($name,$type,$value) = ($1,$2,$4);
	    if ($type eq 'NOTATION') {
		$value = $self->parse->notation($value);
	    } elsif ($type eq 'ENTITY') {
		$value = $self->parse->entity($value);
	    }
	    $new->{$name} =
		new SGMLS_Attribute($name,$type,$value);
	}
	$self->[2] = $new;
    }
    return $self->[2];
}
				# Return a list of attribute names.
sub attribute_names {
    my $self = shift;
    return keys(%{$self->attributes});
}
				# Find an attribute by name.
sub attribute {
    my ($self,$aname) = @_;
    return $self->attributes->{$aname};
}
				# Add a new attribute.
sub set_attribute {
    my ($self,$attribute) = @_;
    $self->attributes->{$attribute->name} = $attribute;
}
				# Check parent by name.
sub in {
    my ($self,$name) = @_;
    if ($self->parent && $self->parent->name eq $name) {
	return $self->parent;
    } else {
	return '';
    }
}
				# Check ancestors by name.
sub within {
    my ($self,$name) = @_;
    for ($self = $self->parent; $self; $self = $self->parent) {
	return $self if ($self->name eq $name);
    }
    return '';
}
    

#
# Data class for an SGML notation.  The only information available
# will be the name, the sysid, and the pubid -- the rest is up to the
# processing application.
#
package SGMLS_Notation;
use Carp;
				# Constructor.
sub new {
    my ($class,$name,$sysid,$pubid) = @_;
    return bless [$name,$sysid,$pubid,{}];
}
				# Accessors.
sub name { return $_[0]->[0]; }
sub sysid { return $_[0]->[1]; }
sub pubid { return $_[0]->[2]; }
sub ext { return $_[0]->[3]; }

#
# Data class for a single SGML entity.  All entities will have a name
# and a type.  Internal entities will be of type CDATA or SDATA only,
# and will have a value rather than a notation and sysid/pubid.  External
# CDATA, NDATA, and SDATA entities will always have notations attached,
# and SUBDOC entities are always external (and will be parsed by SGMLS).
#
# Entity types are as follow:
#      Type     Internal    External
# -----------------------------------------------------------
#     CDATA      x           x
#     NDATA                  x
#     SDATA      x           x
#     SUBDOC                 x
# (newer versions of NSGMLS only:)
#     PI         x
#     TEXT       x           x
#
package SGMLS_Entity;
use Carp;
				# Constructor.
sub new {
    my ($class,$name,$type,$value,$sysid,$pubid,$filenames,$notation) = @_;
    return bless [$name,$type,$value,{},$sysid,$pubid,$filenames,$notation,{}];
}
				# Accessors.
sub name { return $_[0]->[0]; }
sub type { return $_[0]->[1]; }
sub value { return $_[0]->[2]; }
sub data_attributes { return $_[0]->[3]; }
sub sysid { return $_[0]->[4]; }
sub pubid { return $_[0]->[5]; }
sub filenames { return $_[0]->[6]; }
sub notation { return $_[0]->[7]; }
sub ext { return $_[0]->[8]; }
				# Return a list of data-attribute names.
sub data_attribute_names {
    my $self = shift;
    return keys(%{$self->data_attributes});
}
				# Find a data attribute by name.
sub data_attribute {
    my ($self,$aname) = @_;
    return $self->data_attributes->{$aname};
}
				# Add a new data attribute.
sub set_data_attribute {
    my ($self,$data_attribute) = @_;
    $self->data_attributes()->{$data_attribute->name} = $data_attribute;
}

    

#
# Data class for a single SGMLS parse.  The constructor takes a single
# argument, a file handle from which the SGMLS ESIS events will be read
# (it may be a pipe, a fifo, a file, a socket, etc.).  It is essential
# that no two SGMLS objects have the same handle.
#
package SGMLS;
				# Constructor.
sub new {
    my ($class,$handle) = @_;

    # Force unqualified filehandles into caller's package
    my ($package) = caller;
    $handle =~ s/^[^':]+$/$package\:\:$&/;

    return bless {
	'handle' => $handle,
	'event_stack' => [],
	'current_element' => '',
	'current_attributes' => [],
	'current_entities' => {},
	'entity_stack' => [],
	'current_notations' => {},
	'notation_stack' => [],
	'current_sysid' => '',
	'current_pubid' => '',
	'current_filenames' => [],
	'current_file' => '',
	'current_line' => '',
	'appinfo' => '',
	'ext' => {}
	};
}
				# Accessors.
sub element { return $_[0]->{'current_element'}; }
sub file { return $_[0]->{'current_file'}; }
sub line { return $_[0]->{'current_line'}; }
sub appinfo { return $_[0]->{'appinfo'}; }
sub ext { return $_[0]->{'ext'}; }

				# Given its name, look up a notation.
sub notation {
    my ($self,$nname) = @_;
    return $self->{'current_notations'}->{$nname};
}
				# Given its name, look up an entity.
sub entity {
    my ($self,$ename) = @_;
    return $self->{'current_entities'}->{$ename};
}

				# Return the next SGMLS_Event, or ''
				# if the document has finished.
sub next_event {
    my $self = shift;
    my $handle = $self->{'handle'};

				# If there are any queued up events,
				# grab them first.
    if ($#{$self->{event_stack}} >= 0) {
	return pop @{$self->{event_stack}};
    }

  dispatch: while (!eof($handle)) {

      my $c = getc($handle);
      my $data = <$handle>;
      chop $data;

      ($c eq '(') && do {	# start an element
	  $self->{'current_element'} =
	      new SGMLS_Element($data,
				$self->{'current_element'},
				$self->{'current_attributes'},
				$self);
	  $self->{'current_attributes'} = [];
	  return new SGMLS_Event('start_element',
				 $self->{'current_element'},
				 $self);
      };
      
      ($c eq ')') && do {	# end an element
	  my $old = $self->{'current_element'};
	  $self->{'current_element'} = $self->{'current_element'}->parent;
	  return new SGMLS_Event('end_element',$old,$self);
      };
      
      ($c eq '-') && do {	# some data
	  my $sdata_flag = 0;
	  my $out = '';
	  while ($data =~ /\\(\\|n|\||[0-7]{1,3})/) {
	      $out .= $`;
	      $data = $';
				# beginning or end of SDATA
	      if ($1 eq '|') {
		  if ("$out" ne '') {
		      unshift(@{$self->{'event_stack'}},
			      new SGMLS_Event($sdata_flag?'sdata':'cdata',
					      $out,
					      $self));
		      $out = '';
		  }
		  $sdata_flag = !$sdata_flag;
				# record end
	      } elsif ($1 eq 'n') {
		  if ("$out" ne '') {
		      unshift(@{$self->{'event_stack'}},
			      new SGMLS_Event($sdata_flag?'sdata':'cdata',
					      $out,
					      $self));
		      $out = '';
		  }
		  unshift(@{$self->{'event_stack'}},
			  new SGMLS_Event('re','',$self));
	      } elsif ($1 eq '\\') {
		  $out .= '\\';
	      } else {
		  $out .= chr(oct($1));
	      }
	  }
	  $out .= $data;
	  if ("$out" ne '') {
	      unshift(@{$self->{'event_stack'}},
		      new SGMLS_Event($sdata_flag?'sdata':'cdata',
				      $out,
				      $self));
	  }
	      return $self->next_event;
      };
      
      ($c eq '&') && do {	# external entity reference
	  return new SGMLS_Event('entity',
				 ($self->{'current_entities'}->{$data}
				  || croak "Unknown external entity: $data\n"),
				 $self);
      };
      
      ($c eq '?') && do {	# processing instruction
	  return new SGMLS_Event('pi',
				 $data,
				 $self);
      };
      
      ($c eq 'A') && do {	# attribute declaration
				# (will parse only on demand)
	  push @{$self->{'current_attributes'}}, $data;
	  next dispatch;
      };
      
      ($c eq 'a') && do {	# link attribute declaration
	  # NOT YET IMPLEMENTED!
	  next dispatch;
      };
      
      ($c eq 'D') && do {	# data attribute declaration
	  $data =~ /^(\S+) (\S+) (\S+)( (.*))?$/
	    || croak "Bad data-attribute event data: $data";
	  my ($ename,$aname,$type,$value) = ($1,$2,$3,$5);
	  my $entity = $self->{'current_entities'}->{$ename};
	  my $attribute = new SGMLS_Attribute($aname,$type,$value);
	  $entity->set_data_attribute($attribute);
	  next dispatch;
      };
      
      ($c eq 'N') && do {	# notation declaration
	  $self->{'current_notations'}->{$data} =
	      new SGMLS_Notation($data,
				 $self->{'current_sysid'},
				 $self->{'current_pubid'});
	  $self->{'current_sysid'} = '';
	  $self->{'current_pubid'} = '';
	  next dispatch;
      };
      
      ($c eq 'E') && do {	# external entity declaration
	  $data =~ /^(\S+) (\S+) (\S+)$/
	      || croak "Bad external entity event data: $data";
	  my ($name,$type,$nname) = ($1,$2,$3);
	  my $notation = $self->{'current_notations'}->{$nname} if $nname;
	  $self->{'current_entities'}->{$name} =
	      new SGMLS_Entity($name,
			       $type,
			       '',
			       $self->{'current_sysid'},
			       $self->{'current_pubid'},
			       $self->{'current_filenames'},
			       $notation);
	  $self->{'current_sysid'} = '';
	  $self->{'current_pubid'} = '';
	  $self->{'current_filenames'} = [];
	  next dispatch;
      };
      
      ($c eq 'I') && do {	# internal entity declaration
	  $data =~ /^(\S+) (\S+) (.*)$/
	      || croak "Bad external entity event data: $data";
	  my ($name,$type,$value) = ($1,$2,$3);
	  $self->{'current_entities'}->{$name} =
	      new SGMLS_Entity($name, $type, $value);
	  next dispatch;
      };
      
      ($c eq 'T') && do {	# external text entity declaration
	  $self->{'current_entities'}->{$data} =
	      new SGMLS_Entity($data,
			       'TEXT',
			       '',
			       $self->{'current_sysid'},
			       $self->{'current_pubid'},
			       $self->{'current_filenames'},
			       '');
	  $self->{'current_sysid'} = '';
	  $self->{'current_pubid'} = '';
	  $self->{'current_filenames'} = [];
	  next dispatch;
      };
      
      ($c eq 'S') && do {	# subdocument entity declaration
	  $self->{'current_entities'}->{$data} =
	      new SGMLS_Entity($data,
			       'SUBDOC',
			       '',
			       $self->{'current_sysid'},
			       $self->{'current_pubid'},
			       $self->{'current_filenames'},
			       '');
	  $self->{'current_sysid'} = '';
	  $self->{'current_pubid'} = '';
	  $self->{'current_filenames'} = [];
	  next dispatch;
      };
      
      ($c eq 's') && do {	# system id
	  $self->{'current_sysid'} = $data;
	  next dispatch;
      };
      
      ($c eq 'p') && do {	# public id
	  $self->{'current_pubid'} = $data;
	  next dispatch;
      };
      
      ($c eq 'f') && do {	# generated filename
	  push @{$self->{'current_filenames'}}, $data;
	  next dispatch;
      };
      
      ($c eq '{') && do {	# begin subdocument entity
	  my $subdoc = ($self->{'current_entities'}->{$data}||
			croak "Unknown SUBDOC entity $data\n");
	  push @{$self->{'notation_stack'}}, $self->{'current_notations'};
	  push @{$self->{'entity_stack'}}, $self->{'current_entities'};
	  $self->{'current_notations'} = {};
	  $self->{'current_entities'} = {};
	  return new SGMLS_Event('start_subdoc',
				 $subdoc,
				 $self);
      };
      
      ($c eq '}') && do {	# end subdocument entity
	  $self->{'current_notations'} = pop @{$self->{'notation_stack'}};
	  $self->{'current_entities'} = pop @{$self->{'entity_stack'}};
	  return new SGMLS_Event('end_subdoc',
				 ($self->{'current_entities'}->{$data} ||
				  croak "Unknown SUBDOC entity $data\n"),
				 $self);
      };

      ($c eq 'L') && do {	# line number (and file name)
	  $data =~ /^(\d+)( (.*))?$/;
	  $self->{'current_line'} = $1;
	  $self->{'current_file'} = $3 if $3;
	  next dispatch;
      };
      
      ($c eq '#') && do {	# APPINFO parameter
	  $self->{'appinfo'} = $data;
	  next dispatch;
      };
      
      ($c eq 'C') && do {	# document is conforming
	  return new SGMLS_Event('conforming','',$self);
      };
  }
    return '';
}

1;

########################################################################
# Local Variables:
# mode: perl
# End:
########################################################################
