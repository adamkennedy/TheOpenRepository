package Win32::Wix::File;

use strict;
use Carp 'croak';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	name
	id
	diskid
	src
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults and check params
	unless ( $self->src ) {
		croak('Did not provide a src param');
	}
	unless ( $self->name ) {
		$self->{name} = $self->src;
	}
	unless ( $self->id ) {
		$self->{id} = $self->src;
	}
	unless ( $self->diskid ) {
		$self->{diskid} = 1;
	}

	return $self;
}

1;
