package Perl::Dist::Asset::Module;

use strict;
use Carp         'croak';
use Params::Util qw{ _STRING _HASH };
use base 'Perl::Dist::Asset';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.29_01';
}

use Object::Tiny qw{
	name
	type
	force
	extras
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	unless ( defined $self->type ) {
		$self->{type} = 'Module';
	}
	$self->{force} = !! $self->force;

	# Check params
	unless ( _STRING($self->type) ) {
		croak("Missing or invalid type param");
	}
	unless ( _STRING($self->name) ) {
		croak("Missing or invalid name param");
	}
	if ( defined $self->extras and ! _HASH($self->extras) ) {
		croak("Invalid extras param");
	}

	return $self;
}

1;
