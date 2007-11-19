package Perl::Dist::Asset::Library;

# Perl::Dist asset for a Library

use strict;
use Carp         'croak';
use Params::Util qw{ _STRING _HASH };
use base 'Perl::Dist::Asset';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.30';
}

use Object::Tiny qw{
	name
	license
	unpack_to
	build_a
	install_to
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
	unless ( ! defined $self->license or _HASH($self->license) ) {
		croak("Missing or invalid license param");
	}
	unless ( defined $self->unpack_to and ! ref $self->unpack_to ) {
		croak("Missing or invalid unpack_to param");
	}
	unless ( _STRING($self->install_to) or _HASH($self->install_to) ) {
		croak("Missing or invalid install_to param");
	}
	unless ( _HASH($self->build_a) ) {
		croak("Missing or invalid build_a param");
	}

	return $self;
}

1;
