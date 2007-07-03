package CGI::EmailSend;

use strict;
use CGI           ();
use Email::Send   ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create the object
	my $self = bless {
		mailer => undef,
		}, $class;

	return $self;
}

1;
