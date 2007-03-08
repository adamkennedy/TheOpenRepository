package PITA::Scheme::Perl5::CPAN;

=pod

=head1 NAME

PITA::Scheme::Perl5::CPAN - PITA Testing Scheme for Existing CPAN Modules

=head1 DESCRIPTION

The original L<PITA::Scheme::Perl5::Make> and L<PITA::Scheme::Perl5::Build>
testing schemes test a Perl distribution provided via the injector directory.

However, this doesn't integrate in a straight-forward manner with CPAN
clients, and so the testing of these may prove somewhat troublesome.

B<PITA::Scheme::Perl5::CPAN> provides an alternate test scheme that uses the
default L<CPAN> client to install a Perl distribution that already exists on
the CPAN.

This allows the creation of first-generation CPAN testing systems similar to
the original CPAN Testers, that test the distribution only after it has
already been uploaded to the CPAN.

It also lets us shortcut a (at time of writing) currently unsolved problem
relating to the integration of a CPAN client an an arbitrary module.

=head1 METHODS

=cut

use 5.005;
use strict;
use base 'PITA::Scheme';
use Carp         ();
use File::Spec   ();
use File::Which  ();
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.29';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Prepare some additional things
	$self->{dot_cpan} = File::Spec->catdir( $self->workarea, '.cpan' );

	$self;
}

sub dot_cpan {
	$_[0]->{dot_cpan};
}





#####################################################################
# PITA::Scheme Methods

sub default_path {
	File::Which::which('perl') || '';
}

sub prepare_environment {
	my $self = shift;

	# Create the .cpan directory
	unless ( mkdir $self->dot_cpan ) {
		Carp::croak("Failed to create workarea .cpan directory");
	}

	# Save the platform configuration
	$self->{platform} = PITA::XML::Platform->autodetect_perl5;
	unless ( _INSTANCE($self->{platform}, 'PITA::XML::Platform') ) {
		Carp::croak("Failed to capture platform information");
	}

}

sub execute_all {
	my $self = shift;

	# Set the current HOME path to the workarea
	local $ENV{HOME} = $self->workarea;

	# Run the make
	my $command = $self->execute_command('make');

	1;
}

1;
