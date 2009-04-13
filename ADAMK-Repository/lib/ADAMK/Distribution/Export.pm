package ADAMK::Distribution::Export;

use 5.008;
use strict;
use warnings;
use Carp ();

use Object::Tiny::XS qw{
	path
	name
	distribution
};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.08';
}

sub repository {
	$_[0]->distribution->repository;
}

1;
