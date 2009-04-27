package ADAMK::Release::Extract;

use 5.008;
use strict;
use warnings;
use Carp              ();
use ExtUtils::MM_Unix ();
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
	return ExtUtils::MM_Unix->parse_version($file);
}

1;
