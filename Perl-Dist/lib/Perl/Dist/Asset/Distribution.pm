package Perl::Dist::Asset::Distribution;

use strict;
use Carp         'croak';
use Params::Util qw{ _HASH _INSTANCE };
use base 'Perl::Dist::Asset';
use File::Spec;
use File::Spec::Unix;
use URI;
use URI::file;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.90_02';
}

use Object::Tiny qw{
	name
	force
	extras
	automated_testing
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Normalize params
	$self->{force} = !! $self->force;

	# Check params
	unless ( _DIST($self->name) ) {
		croak("Missing or invalid name param");
	}
	if ( defined $self->extras and ! _HASH($self->extras) ) {
		croak("Invalid extras param");
	}

	return $self;
}

sub url { $_[0]->{name} }





#####################################################################
# Main Methods

sub abs_uri {
	my $self = shift;
	my $cpan = _INSTANCE(shift, 'URI')
		or croak("Did not pass a cpan URI");

	# Generate the full root-relative path
	my $name = $self->name;
	my $path = File::Spec::Unix->catfile( 'authors', 'id',
		substr($name, 0, 1),
		substr($name, 0, 2),
		$name,
	);

	return URI->new_abs( $path, $cpan );
}





#####################################################################
# Support Methods

sub _DIST {
	my $it = shift;
	unless ( defined $it and ! ref $it ) {
		return undef;
	}
	unless ( $it =~ q|^([A-Z]){2,}/| ) {
		return undef;
	}
	return $it;
}

1;
