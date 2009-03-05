package POE::Declare::Meta;

=pod

=head1 NAME

POE::Declare::Meta - Metadata object that describes a POE::Declare class

=head1 DESCRIPTION

B<POE::Declare::Meta> objects are constructed and used internally by
L<POE::Declare> during class construction. B<POE::Declare::Meta> objects
are not created directly.

Access to the meta object for a L<POE::Declare> class is via the exported
C<meta> function.

=head1 METHODS

=cut

use 5.008007;
use strict;
use Carp             ();
use Scalar::Util     ();
use Params::Util     ();
use Class::ISA       ();
use Class::Inspector ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';
}

use POE::Declare::Meta::Slot      ();
use POE::Declare::Meta::Message   ();
use POE::Declare::Meta::Event     ();
use POE::Declare::Meta::Timeout   ();
use POE::Declare::Meta::Attribute ();
use POE::Declare::Meta::Internal  ();
use POE::Declare::Meta::Param     ();





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# The name of the class
	my $name = shift;
	unless ( Params::Util::_CLASS($name) ) {
		Carp::croak("Invalid class name '$name'");
	}
	unless ( Class::Inspector->loaded($name) ) {
		Carp::croak("Class $name is not loaded");
	}
	unless ( $name->isa('POE::Declare::Object') ) {
		Carp::croak("Class $name is not a POE::Declare::Object subclass");
	}

	# Create the object
	my $self = bless {
		name     => $name,
		attr     => { },
		alias    => $name,
		sequence => 0,
	}, $class;

	$self;
}





#####################################################################
# Accessors

=pod

=head2 name

The C<name> accessor returns the name of the class for this meta instance.

=cut

sub name {
	$_[0]->{name};
}

=pod

=head2 alias

The C<alias> accessor returns the alias root string that will be used for
objects that are created of this type.

Normally this will be identical to the class C<name> but may be changed
at constructor time.

=cut

sub alias {
	$_[0]->{alias};
}

=pod

=head2 sequence

Because each object has its own L<POE::Session>, each session also needs
its own session alias, and the session alias is derived from a combination
of the C<alias> method an an incrementing C<sequence> value.

The C<sequence> accessor returns the most recently requested value from the
sequence. As with sequence in SQL, not all values pulled from the sequence
will necesarily be used in an object, and objects will not necesarily have
incrementing sequence values.

=cut

sub sequence {
	$_[0]->{sequence};
}





#####################################################################
# Methods

=pod

=head2 next_alias

The C<next_alias> method generates and returns a new session alias,
by taking the C<alias> base string and appending an incremented
C<sequence> value.

The typical alias string returned will look something like
C<'My::Class.123'>.

=cut

sub next_alias {
	$_[0]->{alias} . '.' . ++$_[0]->{sequence};
}

=pod

=head2 super_path

The C<super_path> method is provided as a convenience, and returns a list
of the inheritance path for the class.

It is equivalent to C<Class::ISA::self_and_super_path('My::Class')>.

=cut

sub super_path {
	Class::ISA::self_and_super_path( $_[0]->name );
}

sub _compile {
	my $self = shift;
	my $name = $self->name;
	my $attr = $self->{attr};

	# Go over all our methods, and add any required events
	my $methods = Class::Inspector->methods($name, 'expanded');
	foreach my $method ( @$methods ) {
		my $mname  = $method->[2];
		my $mcode  = $method->[3];
		my $maddr  = Scalar::Util::refaddr($mcode);
		my $mevent = $POE::Declare::EVENT{$maddr} or next;
		my $mattr  = $self->attr($mname);
		if ( $mattr ) {
			# Make sure the existing attribute is an event
			next if $mattr->isa('POE::Declare::Meta::Event');
			Carp::croak("Event '$mname' in $name clashes with non-event in parent class");
			next;
		}

		# Add an attribute for the event
		my $class = $mevent->[0];
		my @param = @$mevent[1..$#$mevent];
		$self->{attr}->{$mname} = $class->new(
			name => $mname,
			@param,
		);
	}

	# Get all the package fragments
	my @parts = map { $attr->{$_}->_compile } sort keys %$attr;
	my @main  = (
		"package " . $self->name . ";",
		map { $_->{package} || '' } @parts,
	);

	# Compile the Perl code
	my $code = join "\n\n", @main;
	eval $code;
	Carp::croak("Failed to compile code for " . $self->name) if $@;

	return 1;
}

# Resolve the inline states for a class
sub package_states {
	my $self = shift;
	unless ( exists $self->{package_states} ) {
		# Cache for speed reasons
		$self->{package_states} = [
			sort map {
				$_->name
			} grep {
				$_->isa('POE::Declare::Meta::Event')
			} $self->attrs
		];
	}
	if ( wantarray ) {
		return @{$self->{package_states}};
	} else {
		return $self->{package_states};
	}
}

=pod

=head2 attr

  my $attribute = My::Class->meta->attr('foo');

The C<attr> method is used to get a single named attribute meta object
within the class meta object.

Returns a L<POE::Declare::Meta::Attribute> object or C<undef> if no such
named attribute exists.

=cut

sub attr {
	my $self = shift;
	my $name = shift;
	foreach my $c ( $self->super_path ) {
		my $meta = $POE::Declare::META{$c} or next;
		my $attr = $meta->{attr}->{$name}  or next;
		return $attr;
	}
	return undef;
}

# Fetch all named attributes (from this or parents)
sub attrs {
	my $self = shift;
	my %hash = ();
	foreach my $c ( $self->super_path ) {
		my $meta = $POE::Declare::META{$c} or next;
		my $attr = $meta->{attr};
		foreach ( keys %$attr ) {
			$hash{$_} = $attr->{$_};
		}
	}
	return values %hash;
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

L<POE>

=head1 COPYRIGHT

Copyright 2006 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
