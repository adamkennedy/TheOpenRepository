package Perl::Dist::Asset::File;

# The simplest asset, a File asset pulls a simple file
# from an arbitrary location/URI and copies it into the
# build.

use strict;
use Carp         'croak';
use Params::Util qw{ _STRING };
use base 'Perl::Dist::Asset';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.29_01';
}

use Object::Tiny qw{
	install_to
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->install_to) ) {
		croak("Missing or invalid install_to param");
	}

	return $self;
}

1;
