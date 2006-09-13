package POE::Declare::Meta;

# Provides a simple metaclass object for POE::Declare

use strict;
use Carp             qw{ croak   };
use Scalar::Util     qw{ refaddr };
use List::Util       qw{ first   };
use Params::Util     qw{ _CLASS  };
use Class::ISA       qw{ self_and_super_path };
use Class::Inspector ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# The name of the class
	my $name  = shift;
	unless ( _CLASS($name) ) {
		croak("Invalid class name '$name'");
	}
	unless ( Class::Inspector->loaded($name) ) {
		croak("Class $name is not loaded");
	}
	unless ( $name->isa('POE::Declare::Object') ) {
		croak("Class $name is not a POE::Declare::Object subclass");
	}

	# Create the object
	my $self  = bless {
		name     => $name,
		attr     => { },
		alias    => $name,
		sequence => 0,
		}, $class;

	$self;
}

sub name {
	$_[0]->{name};
}

sub alias {
	$_[0]->{alias};
}

sub sequence {
	$_[0]->{sequence};
}




#####################################################################
# Methods

sub next_alias {
	$_[0]->{alias} . '.' . ++$_[0]->{sequence};
}

sub super_path {
	Class::ISA::self_and_super_path( $_[0]->name );
}

sub compile {
	my $self = shift;
	my $name = $self->name;
	my $attr = $self->{attr};

	# Go over all our methods, and add any required events
	my $methods = Class::Inspector->methods($name, 'expanded');
	foreach my $method ( @$methods ) {
		my $mname = $method->[2];
		my $mcode = $method->[3];
		next unless $POE::Declare::EVENT{Scalar::Util::refaddr $mcode};
		my $method_attr = $self->attr($mname);
		if ( $method_attr ) {
			# Make sure the existing attribute is an event
			next if $method_attr->isa('POE::Declare::Meta::Event');
			croak("Event '$mname' in $name clashes with non-event in parent class");
		} else {
			# Add an attribute for the event
			require POE::Declare::Meta::Event;
			$self->{attr}->{$mname} = POE::Declare::Meta::Event->new( name =>$mname );
		}
	}

	# Get all the package fragments
	my @parts = map { $attr->{$_}->compile } sort keys %$attr;
	my @main  = (
		"package " . $self->name . ";",
		map { $_->{package} || '' } @parts,
		);

	# Compile the Perl code
	my $code = join "\n\n", @main;
	eval $code;
	croak("Failed to compile code for " . $self->name) if $@;

	return 1;
}

# Resolve the inline states for a class
sub package_states {
	sort map { $_->name } grep { $_->isa('POE::Declare::Meta::Event') } $_[0]->attrs;
}

# Fetch a named attribute (from this or parents)
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
	values %hash;
}

1;
