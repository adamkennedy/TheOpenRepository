package PITA::TestHarness::Perl5Build;

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

	# We need a Build.PL
	$self->{buildpl} = File::Spec->catfile( $self->dir, 'Build.PL' );
	unless ( -f $self->{buildpl} and -r _ ) {
		Carp::croak("perl5.build distribution harness requires a Makefile.PL");
	}

	$self;
}

sub scheme { 'perl5.build' }

sub buildpl { $_[0]->{buildpl} }





#####################################################################
# Main Methods


sub _run_buildpl {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('perl Build.PL');
}

sub _run_build {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('Build');
}

sub _run_buildtest {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('Build test');
}

sub _run_buildinstall {
	my $self = shift;
	$self->_chdir( $self->dir );
	PITA::Report::Command->run('Build install');
}

1;
