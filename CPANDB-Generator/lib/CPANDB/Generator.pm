package CPANDB::Generator;

use 5.008005;
use strict;
use warnings;
use File::Temp    0.21 ();
use CPAN::SQLite 0.197 ();

our $VERSION = '0.01';





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Default the CPAN path to a temp directory,
	# so that we don't disturb any existing files.
	unless ( defined $self->cpan ) {
		$self->{cpan} = File::Temp::tempdir( CLEANUP => 1 );
	}

	return $self;
}

sub cpan {
	$_[0]->{cpan};
}

1;
