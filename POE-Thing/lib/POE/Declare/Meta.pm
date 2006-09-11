package POE::Declare::Meta;

# Provides a simple metaclass object for POE::Declare

use strict;
use Carp             qw{ croak  };
use Params::Util     qw{ _CLASS };
use Class::Inspector ();
use Class::ISA       qw{ self_and_super_path };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
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
	my $self  = shift;
	my @super = Class::ISA::self_and_super_path( $self->name );
	if ( $super[-1] eq 'POE::Declare::Object' ) {
		pop @super;
	}
	return @super;
}

sub compile {
	my $self = shift;
	my $attr = $self->{attr};

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
	my $self   = shift;
	my @path   = $self->super_path;
	my %events = map  { %{POE::Declare::EVENT} }
	             grep { $POE::Declare::EVENT{$_} }
	             $self->super_path;
	return sort keys %events;
}

1;
