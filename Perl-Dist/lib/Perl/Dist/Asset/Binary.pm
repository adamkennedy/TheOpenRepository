package Perl::Dist::Asset::Binary;

use strict;
use Carp           'croak';
use Params::Util   qw{ _STRING _HASH };
use base 'Perl::Dist::Asset';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.90_02';
}

use Object::Tiny qw{
	name
	install_to
	license
	extras
};

	



#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Missing or invalid name param");
	}
	unless ( _STRING($self->install_to) or _HASH($self->install_to) ) {
		croak("Missing or invalid install_to param");
	}
	if ( defined $self->extras and ! _HASH($self->extras) ) {
		croak("Invalid extras param");
	}

	return $self;
}

1;
