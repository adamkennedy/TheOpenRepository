package POE::Declare::Meta;

# Provides a simple metaclass object for POE::Declare

use 5.008007;
use strict;
use Carp             ();
use Scalar::Util     ();
use Params::Util     ();
use Class::ISA       ();
use Class::Inspector ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
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
	my @parts = map { $attr->{$_}->compile } sort keys %$attr;
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
	if ( wantarray ) {
		return sort map {
			$_->name
		} grep {
			$_->isa('POE::Declare::Meta::Event')
		} $_[0]->attrs;
	} else {
		return scalar grep {
			$_->isa('POE::Declare::Meta::Event')
		} $_[0]->attrs;
	}
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
	return values %hash;
}

1;
