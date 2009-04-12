package ADAMK::Distribution::Export;

use 5.008;
use strict;
use warnings;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.06';
}

use Object::Tiny qw{
	path
	name
	distribution
};

sub repository {
	$_[0]->distribution->repository;
}

1;
