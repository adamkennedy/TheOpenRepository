package Aspect::Point::Static;

use strict;
use warnings;
use Carp          ();
use Aspect::Point ();

our $VERSION = '0.97_03';
our @ISA     = 'Aspect::Point';





######################################################################
# Error on anything this doesn't support

sub return_value {
	Carp::croak("Cannot call return_value on static part of join point");
}

sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	$key =~ s/^.*:://;
	Carp::croak("Cannot call $key on static part of join point");
}

1;
