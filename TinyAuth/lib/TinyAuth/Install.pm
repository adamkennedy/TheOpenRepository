package TinyAuth::Install;

use 5.005;
use strict;
use base 'Module::CGI::Install';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub prepare {
	my $self = shift;

	# Add the files to install
	$self->add_script('TinyAuth', 'tinyauth');
	$self->add_class('TinyAuth');

	# Hand off to the parent class
	return $self->SUPER::prepare(@_);
}

1;
