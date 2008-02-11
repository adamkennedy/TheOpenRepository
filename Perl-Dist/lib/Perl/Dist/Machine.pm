package Perl::Dist::Machine;

use 5.005;
use strict;
use Carp         'croak';
use Perl::Dist   ();
use Params::Util qw{ _STRING _IDENTIFIER _ARRAY _DRIVER };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.90_02';
}

use Object::Tiny qw{
	class
	common
	output
};





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# All passed arguments go into the common param pool by default
	my $self = bless { @_,
		dimensions => [ ],
		options    => { },
		state      => undef,
	}, $class;

	# Check params
	unless ( _DRIVER($self->class) ) {
		croak("Missing or invalid class param");
	}
	unless ( _STRING($self->output) ) {
		croak("Missing or invalid output param");
	}
	unless ( -d $self->output and -w $self->output ) {
		croak("The output directory does not exist, or is not writable");
	}
	unless ( _ARRAY($self->common) ) {
		croak("Did not provide a common param");
	}

	return $self;
}

sub dimensions {
	return @{$_[0]->{dimensions}};
}





#####################################################################
# Setup Methods

sub add_dimension {
	my $self = shift;
	my $name = _IDENTIFIER(shift) or croak("Missing or invalid dimension name");
	if ( defined $self->state ) {
		croak("Cannot alter params once iterating");
	}
	if ( $self->{options}->{$name} ) {
		croak("The dimension '$name' already exists");
	}
	push @{ $self->{dimensions}->{$name} }, $name;
	$self->{options}->{$name} = [ ];
	return 1;
}

sub add_option {
	my $self = shift;
	my $name = _IDENTIFIER(shift) or croak("Missing or invalid dimension name");
	if ( defined $self->state ) {
		croak("Cannot alter params once iterating");
	}
	unless ( $self->{options}->{$name} ) {
		croak("The dimension '$name' does not exist");
	}
	push @{ $self->{options}->{$name} }, [ @_ ];
	return 1;
}





#####################################################################
# Iterator Methods

sub next {
	my $self = shift;

	# Initialize the iterator if needed
	if ( $self->state ) {
		# Move to the next position
	} else {
		$self->{state} = [ ];
		foreach my $name ( $self->dimensions ) {
			unless ( @{ $self->options->{$name} } ) {
				croak("No options for dimension '$name'");
			}
			push @{ $self->{state} }, $name;
		}
	}


}





#####################################################################
# Execution Methods

sub run {

}

1;
