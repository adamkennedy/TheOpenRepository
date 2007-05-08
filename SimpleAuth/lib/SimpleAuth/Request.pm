package SimpleAuth::Request;

use 5.005;
use strict;
use Carp         ();
use CGI          ();
use Params::Util qw{ _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	cgi
	};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params and apply defaults
	$self->{cgi} ||= CGI->new;
	unless ( _INSTANCE($self->cgi, 'CGI') ) {
		croak("The required cgi param is not a CGI object");
	}


	return $self;
}

1;
