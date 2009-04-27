package ADAMK::Release::Extract;

use 5.008;
use strict;
use warnings;
use Carp              ();
use ADAMK::Repository ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.11';
	@ISA     = qw{
		ADAMK::Role::File
		ADAMK::Role::Changes
		ADAMK::Role::Make
	};
}

use Class::XSAccessor
	getters => {
		name    => 'name',
		release => 'release',
	};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub distribution {
	$_[0]->release->distribution;
}

sub repository {
	$_[0]->distribution->repository;
}

sub trace {
	shift->repository->trace(@_);
}





#####################################################################
# Module::Install Enhancement

# Find the version of Module::Install bundled in the tarball
sub inc_mi {
	my $self = shift;
	my $file = $self->file('inc/Module/Install.pm');
	unless ( -f $file ) {
		return undef;
	}

	# Find the version
	my $makefile = $self->_slurp($file);
	unless ( $makefile =~ /use\s+inc::Module::Install\b/ ) {
		# Doesn't use Module::Install
		return undef;
	}
	unless ( $makefile =~ /use\s+inc::Module::Install(?:::DSL)?\s+([\d.]+)/ ) {
		# Does not use a specific version of Module::Install
		return 0;
	}

	return "$1";
}

1;
