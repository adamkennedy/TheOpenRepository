package PITA::Scheme::Perl5::Make;

# Class for implementing the perl5-make testing scheme

use strict;
use base 'PITA::Scheme::Perl';
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

# Do the extra common checks we couldn't do in the main class
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	$self;
}





#####################################################################
# PITA::Scheme Methods

sub prepare_package {
	my $self = shift;

	# Do the generic unpacking
	$self->SUPER::prepare_package(@_);

	# Validate that the package has a Makefile.PL in the root
	unless ( -f $self->workarea_file('Makefile.PL') ) {
		Carp::croak("Package does not contain a Makefile.PL");
	}

	$self;
}

1;
