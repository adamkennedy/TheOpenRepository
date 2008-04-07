package Perl::Dist::Asset::Perl;

# Perl::Dist asset for the Perl source code itself

use strict;
use Carp         'croak';
use Params::Util qw{ _STRING _HASH };
use base 'Perl::Dist::Asset';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.00';
}

use Object::Tiny qw{
	name
	force
	license
	unpack_to
	install_to
	patch
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	$self->{unpack_to} = '' unless defined $self->unpack_to;

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Missing or invalid name param");
	}
	unless ( _HASH($self->license) ) {
		croak("Missing or invalid license param");
	}
	unless ( defined $self->unpack_to and ! ref $self->unpack_to ) {
		croak("Missing or invalid unpack_to param");
	}
	unless ( _STRING($self->install_to) ) {
		croak("Missing or invalid install_to param");
	}
	if ( $self->patch and ! _HASH($self->patch) ) {
		croak("Invalid patch param");
	}
	$self->{force} = !! $self->force;

	return $self;
}

1;
