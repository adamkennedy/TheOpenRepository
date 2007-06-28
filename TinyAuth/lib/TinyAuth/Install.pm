package TinyAuth::Install;

use 5.005;
use strict;
use base 'CGI::Install';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub prepare {
	my $self = shift;

	# Add the files to install
	$self->add_bin('tinyauth');
	$self->add_class('TinyAuth');

	# Hand off to the parent class
	return $self->SUPER::prepare(@_);
}

1;
