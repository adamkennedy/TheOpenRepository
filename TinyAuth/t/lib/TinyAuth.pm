package t::lib::TinyAuth;

# Testing subclass of TinyAuth that captures instead of prints
use strict;
use base 'TinyAuth';
use YAML::Tiny ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	stdout
};

sub new {
	my $self = shift->SUPER::new(@_);

	# Add the output
	$self->{stdout} = '';

	return $self;
}

sub print {
	my $self = shift;
	$self->{stdout} .= join '', @_;
	return 1;
}

1;
