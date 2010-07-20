package ADAMK::Distribution::Export;

use 5.008;
use strict;
use warnings;
use Carp              ();
use ADAMK::Repository ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.12';
	@ISA     = qw{
		ADAMK::Role::File
		ADAMK::Role::SVN
		ADAMK::Role::Changes
		ADAMK::Role::Make
	};
}

use Class::XSAccessor
	getters => {
		name         => 'name',
		distribution => 'distribution',
	};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub repository {
	$_[0]->distribution->repository;
}

sub trace {
	shift->repository->trace(@_);
}

1;
