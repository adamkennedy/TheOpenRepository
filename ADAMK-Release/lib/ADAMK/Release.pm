package ADAMK::Release;

use 5.10.0;
use strict;
use warnings;
use Params::Util    ();
use GitHub::Extract ();

our $VERSION = '0.01';

use Object::Tiny 1.01 qw{
	github
};





######################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Inflate the github object if needed
	if ( Params::Util::_HASH($self->github) ) {
		$self->{github} = GitHub::Extract->new( %{$self->github} );
	}
	unless ( Params::Util::_INSTANCE($self->github, 'GitHub::Extract')) {
		die "Missing or invalid GitHub specification";
	}

	return $self;
}





######################################################################
# Main Methods

sub run {
	my $self = shift;

	
}

1;
