package PITA::TestHarness::Perl5Make;

use strict;
use Carp                  ();
use File::Spec            ();
use PITA::Report::Command ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# We need a Makefile.PL
	$self->{makefilepl} = File::Spec->catfile( $self->dir, 'Makefile.PL' );
	unless ( -f $self->{makefilepl} and -r _ ) {
		Carp::croak("perl5.make distribution harness requires a Makefile.PL");
	}

	$self;
}

sub scheme { 'perl5.make' }

sub makefilepl { $_[0]->{makefilepl} }





#####################################################################
# Main Methods

sub _run_makefilepl {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('perl Makefile.PL');
}

sub _run_make {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('make');
}

sub _run_maketest {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('make test');
}

sub _run_makeinstall {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('make install');
}

1;
