package POE::Declare;

=pod

=head1 NAME

POE::Declare - A POE abstraction layer for conciseness and simplicity

=head1 SYNOPSIS

  package MyComponent;
  
  use strict;
  use POE::Declare;
  
  declare foo => 'Attribute';
  declare bar => 'Internal';
  
  sub hello : Event {
      print "Hello World!\n";
  }
  
  sub hello_timeout : Timeout(30) {
      print "Alas, I die!\n";
  }
  
  1;

=head1 DESCRIPTION

B<WARNING: THIS CODE IS EXPERIMENTAL AND SUBJECT TO CHANGE
WITHOUT NOTICE>

L<POE> is a very powerful and flexible system for doing asynchronous
programming.

But personally, I find it confusing and tricky to use at times.

In particular, I have found it hard to resolve L<POE>'s way of
programming with the highly abstracted OO that I am used to,
with layer stacked upon layer ad-infinitum to create powerful
and complex systems that are still easy to maintain.

I have found this particularly noticable as the scale of a
codebase gets later. At three levels of abstraction the layering
become quite difficult, and beyond this it became worse and worse.

B<POE::Declare> is my attempt to resolve this problem by locking
down some of the traditional flexibility of POE, and by (hopefully)
makeing it easier to split the implementation of each object between
an object-oriented half and a POE half. 

This will hopefully allow me to utilise POE's asynchronous nature,
while retaining the traditional codebase scaling capability
provided by normal OO.

Of course, this entire exercise is something of a grand experiment
and it may well turn out that I am wrong. But I think I'm heading
in the right general direction (I just don't know if I'm taking
quite the right path).

=head1 ARCHITECTURE

B<POE::Declare> is composed of three main modules, and a tree of
slot/attribute classes.

=head2 POE::Declare

=head2 POE::Declare::Object

L<POE::Declare::Object> is the abstract base class for all classes created
by B<POE::Declare>.

=head2 POE::Declare::Meta

L<POE::Declare::Meta> implements the metadata objects that describe each of
the B<POE::Declare> classes.

=head2 POE::Declare::Slot

  POE::Declare::Meta::Slot
    POE::Declare::Meta::Internal
    POE::Declare::Meta::Attribute
      POE::Declare::Meta::Param
    POE::Declare::Meta::Message
    POE::Declare::Meta::Event
      POE::Declare::Meta::Timeout

=head2 POE::Declare::Meta::Internal

L<POE::Declare::Meta::Internal> is a slot class that won't generate any
functionality, but allows you to reserve an attribute for internal use
so that they won't be used by any sub-classes.

=head2 POE::Declare::Meta::Attribute

L<POE::Declare::Meta::Attribute> is a slot class used for readable
attributes.

=head2 POE::Declare::Meta::Param

L<POE::Declare::Meta::Attribute> is a slot class for attributes that
are provided to the constructor as a parameter.

=head2 POE::Declare::Meta::Message

TO BE COMPLETED

=head2 POE::Declare::Meta::Event

L<POE::Declare::Meta::Event> is a class for named POE events that can be
called or yielded to by other POE messages/events.

=head2 POE::Declare::Meta::Timeout

L<POE::Declare::Meta::Timeout> is a L<POE::Declare::Meta::Event> sub-class
that is designed to trigger from an alarm.

=head1 FUNCTIONS

For the first few releases, I plan to leave this module undocumented.

That I am releasing this distribution at all is more of a way to
mark my progress, and to allow other POE/OO people to look at the
implementation and comment.

=cut

use 5.008007;
use strict;
use Carp               ();
use Exporter           ();
use List::Util         ();
use Params::Util       qw{ _IDENTIFIER _CLASS };
use Class::Inspector   ();
use POE;
use POE::Session       ();
use POE::Declare::Meta ();

# The base class requires POE::Declare to be fully compiled,
# so load it in post-BEGIN with a require rather than at
# BEGIN-time with a use.
require POE::Declare::Object;

# Provide the SELF constant
use constant SELF => HEAP;

use vars qw{$VERSION @ISA @EXPORT %ATTR %EVENT %META};
BEGIN {
	$VERSION = '0.06';
	@ISA     = qw{ Exporter };
	@EXPORT  = qw{ SELF declare compile };

	# Metadata Storage
	%ATTR    = ();
	%EVENT   = ();
	%META    = ();
}





#####################################################################
# Declaration Functions

sub import {
	my $pkg     = shift;
	my $callpkg = caller($Exporter::ExportLevel);

	# POE::Declare should only be loaded on empty classes.
	# We only use the simple case here of checking for $VERSION or @ISA
	no strict 'refs';
	if ( defined ${"$callpkg\::VERSION"} ) {
		Carp::croak("$callpkg already exists, cannot use POE::Declare");
	}
	if ( defined @{"$callpkg\::ISA"} ) {
		# Are we a subclass of an existing POE::Declare class
		if ( $callpkg->isa('POE::Declare::Object') ) {
			# Yes, don't set up anything, just do the exports
			local $Exporter::ExportLevel += 1;
			return $pkg->SUPER::import(@_);
		}

		# This isn't a POE::Declare class
		Carp::croak("$callpkg already exists, cannot use POE::Declare");
	}

	# Set @ISA for the package, which does most of the work
	@{"$callpkg\::ISA"} = qw{ POE::Declare::Object };

	# Export the symbols
	local $Exporter::ExportLevel += 1;
	$pkg->SUPER::import(@_);

	# Make "use POE::Declare;" an implicit "use POE;" as well
	eval "package $callpkg; use POE;";
	die $@ if $@;

	return 1;
}

=pod

=head2 declare

  declare one   => 'Internal';
  declare two   => 'Attribute';
  declare three => 'Param';
  declare four  => 'Message';

The C<declare> function is exported by default. It takes two parameters,
a slot name and a slot type.

The slot name can be any legal Perl identifier.

The slot type should be one of C<Internal>, C<Attribute>, C<Param> or
C<Message>.

Creates the new slot, throws an exception on error.

=cut

sub declare (@) {
	my $pkg = caller();
	local $Carp::CarpLevel += 1;
	_declare( $pkg, @_ );
}

sub _declare {
	my $pkg = shift;
	if ( $META{$pkg} ) {
		Carp::croak("Too late to declare additions to $pkg");
	}

	# What is the name of the attribute
	my $name = shift;
	unless ( _IDENTIFIER($name) ) {
		Carp::croak("Did not provide a valid attribute name");
	}

	# Has the attribute already been defined
	if ( $ATTR{$pkg}->{$name} ) {
		Carp::croak("Attribute $name already defined in class $pkg");
	}

	# Resolve the attribute class
	my $type = do {
		local $Carp::CarpLevel += 1;
		_attribute_class(shift);
	};

	# Is the class an attribute class?
	unless ( $type->isa('POE::Declare::Meta::Slot') ) {
		Carp::croak("The class $type is not a POE::Declare::Slot");
	}

	# Create and save the attribute
	$ATTR{$pkg}->{$name} = $type->new(
		name => $name,
		@_,
	);

	return 1;
}

# Resolve an attribute type
sub _attribute_class {
	my $type = shift;
	if ( _IDENTIFIER($type) ) {
		$type = "POE::Declare::Meta::$type";
	} elsif ( _CLASS($type) ) {
		$type = $type;
	} else {
		Carp::croak("Invalid attribute type");
	}

	# Try to load the attribute class
	my $file = $type . '.pm';
	$file =~ s{::}{/}g;
	eval { require $file };
	if ( $@ ) {
		local $Carp::CarpLevel += 1;
		my $quotefile = quotemeta $file;
		if ( $@ =~ /^Can\'t locate $quotefile/ ) {
			Carp::croak("The attribute class $type does not exist");
		} else {
			Carp::croak($@);
		}
	}

	return $type;
}

=pod

=head2 compile

The C<compile> function indicates that all attributes and events have
been defined and the structure should be finalised and compiled.

Returns true or throws an exception.

=cut

sub compile {
	my $pkg = @_ ? shift : caller();

	# Shortcut if already compiled
	return 1 if $META{$pkg};

	# Create the meta object
	my $meta  = $META{$pkg} = POE::Declare::Meta->new($pkg);
	my @super = reverse $meta->super_path;

	# Make sure any parent POE::Declare classes are compiled
	foreach my $parent ( @super ) {
		next if $META{$parent};
		Carp::croak("Cannot compile $pkg, parent class $parent not compiled");
	}

	# Are any attributes already defined in our parents?
	foreach my $name ( sort keys %{$ATTR{$pkg}} ) {
		my $found = List::Util::first { 
			$ATTR{$_}->{attr}->{$name}
		} @super;
		Carp::croak(
			"Duplicate attribute '$name' already defined in "
			. $found->name
		) if $found;
		$meta->{attr}->{$name} = $ATTR{$pkg}->{$name};
	}

	# Compile the individual parts
	$meta->_compile;
}

# Get the meta-object for a class.
# Primarily used for testing purposes.
sub meta {
	$META{$_[0]};
}

sub next_alias {
	my $meta = $META{$_[0]};
	unless ( $meta ) {
		Carp::croak("Cannot instantiate $_[0], class not defined");
	}
	$meta->next_alias;
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
