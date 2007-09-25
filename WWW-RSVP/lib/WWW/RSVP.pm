package WWW::RSVP;

# Simple package for staying "active" on www.rsvp.com.au, by logging in

use strict;
use Carp           ();
use Params::Util   '_INSTANCE';
use WWW::Mechanize ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	mech
	username
	password
};

my $LOGIN = 'http://www.rsvp.com.au/login.asp';





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	$self->{mech} ||= WWW::Mechanize->new;
	unless ( _INSTANCE($self->mech, 'WWW::Mechanize') ) {
		Carp::croak("Invalid mech param");
	}
	unless ( $self->username ) {
		Carp::croak("Did not provide a username");
	}
	unless ( $self->password ) {
		Carp::croak("Did not provide a password");
	}

	return $self;
}





#####################################################################
# Main Methods

sub login {
	my $self = shift;

	# Get the login page
	$self->mech->get( $LOGIN );

	1;
}

1;
